from typing import Dict, List, Tuple, Any, Optional
import uvicorn
from fastapi import FastAPI, HTTPException, File, UploadFile, Form, Header
from fastapi.security import HTTPBearer
from pydantic import BaseModel
from starlette.middleware.cors import CORSMiddleware
from telethon import TelegramClient, errors
from telethon.sessions import StringSession
from telethon.tl.types import PeerChannel, InputMediaUploadedPhoto, User
from telethon.tl.functions.channels import GetFullChannelRequest
import json
import os
import tempfile
from datetime import datetime
import pytz
import asyncio
import logging
import httpx
import re

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

sessions: Dict[str, 'TelegramAuth'] = {}
drafts: List[Dict] = []

class TelegramAuth:
    def __init__(self, api_id: int, api_hash: str):
        self.client: TelegramClient = None
        self.api_id: int = api_id
        self.api_hash: str = api_hash
        self.phone_code_hash: str = None
        self.phone: str = None

    async def send_code(self, phone: str) -> bool:
        self.phone = phone
        try:
            self.client = TelegramClient(StringSession(), self.api_id, self.api_hash)
            await self.client.connect()

            result = await self.client.send_code_request(phone)
            self.phone_code_hash = result.phone_code_hash
            return True
        except errors.PhoneMigrateError as e:
            await self.client.disconnect()
            self.client = TelegramClient(
                StringSession(),
                self.api_id,
                self.api_hash,
                dc_id=e.new_dc
            )
            await self.client.connect()
            result = await self.client.send_code_request(phone)
            self.phone_code_hash = result.phone_code_hash
            return True
        except Exception as e:
            logger.error(f"Ошибка в отправке кода телефона {phone}: {str(e)}")
            return False

    async def sign_in(self, code: str, password: str = None) -> bool:
        if not self.client or not self.phone_code_hash:
            raise RuntimeError("Сначала вызовите send_code()")

        try:
            await self.client.sign_in(
                phone=self.phone,
                code=code,
                phone_code_hash=self.phone_code_hash
            )
            return True
        except errors.SessionPasswordNeededError:
            if not password:
                raise ValueError("Требуется пароль для двухфакторной аутентификации")
            await self.client.sign_in(password=password)
            return True
        except Exception as e:
            logger.error(f"Ошибка входа для телефона {self.phone}: {str(e)}")
            return False

    async def get_channels(self) -> List[Dict]:
        if not await self.client.is_user_authorized():
            raise RuntimeError("Пользователь не авторизован")

        dialogs = await self.client.get_dialogs()
        writable_channels: List[Dict] = []

        for dialog in dialogs:
            if not dialog.is_channel:
                continue

            try:
                channel = await self.client.get_entity(dialog.id)
                full_channel = await self.client(GetFullChannelRequest(channel=channel))

                can_write = False
                if hasattr(full_channel.full_chat, 'creator') and full_channel.full_chat.creator:
                    can_write = True
                    logger.info(f"Пользователь является создателем канала: {dialog.title}")

                if not can_write and hasattr(full_channel.full_chat, 'admin_rights') and full_channel.full_chat.admin_rights:
                    if full_channel.full_chat.admin_rights.post_messages:
                        can_write = True
                        logger.info(f"Пользователь является администратором с правами публикации в канале: {dialog.title}")

                if not can_write:
                    try:
                        await self.client.send_message(channel, "Тестовое сообщение", silent=True)
                        can_write = True
                        logger.info(f"Пользователь может публиковать в канале (проверено тестовым сообщением): {dialog.title}")
                        async for message in self.client.iter_messages(channel, limit=1):
                            if message.message == "Тестовое сообщение":
                                await message.delete()
                                break
                    except errors.ChannelPrivateError:
                        logger.info(f"Пользователь не может публиковать в канале (приватный канал): {dialog.title}")
                    except errors.UserNotParticipantError:
                        logger.info(f"Пользователь не является участником канала: {dialog.title}")
                    except Exception as e:
                        logger.info(f"Пользователь не может публиковать в канале (тестовое сообщение не прошло): {dialog.title}, ошибка: {str(e)}")

                if can_write:
                    writable_channels.append({
                        'title': dialog.title.encode('utf-8', errors='replace').decode('utf-8', errors='replace'),
                        'id': dialog.id
                    })
            except Exception as e:
                logger.error(f"Ошибка при проверке канала {dialog.title}: {str(e)}")
                continue

        return writable_channels

    async def create_post(
        self,
        chat_usernames: List[str],
        title: str,
        description: str,
        image_paths: List[str] = None,
        schedule: datetime = None
    ) -> bool:
        if not await self.client.is_user_authorized():
            raise RuntimeError("Пользователь не авторизован")

        try:
            title = title.encode('utf-8').decode('utf-8')
            description = description.encode('utf-8').decode('utf-8')
        except UnicodeEncodeError as e:
            logger.error(f"Ошибка кодирования в заголовке или описании: {str(e)}")
            title = title.encode('utf-8', errors='replace').decode('utf-8')
            description = description.encode('utf-8', errors='replace').decode('utf-8')

        message = f"{title}\n\n{description}"
        logger.info(f"Подготовленное сообщение: {message}")
        if len(message) > 1024:
            message = message[:1021] + "..."
            logger.info(f"Сообщение обрезано до 1024 символов: {message}")

        failed_chats: List[str] = []

        for username in chat_usernames:
            logger.info(f"Попытка доступа к каналу: {username}")
            try:
                channel = None
                if username.startswith('channel_'):
                    try:
                        channel_id = int(username.replace('channel_', ''))
                        channel = await self.client.get_entity(PeerChannel(channel_id))
                    except ValueError:
                        logger.error(f"Неверный формат ID канала: {username}")
                        failed_chats.append(username)
                        continue
                else:
                    channel = await self.client.get_entity(username)

                logger.info(f"Канал найден: {channel.title}, ID: {channel.id}")

                if image_paths and len(image_paths) > 0:
                    logger.info(f"Изображения для отправки: {image_paths}")
                    for path in image_paths:
                        if not os.path.exists(path):
                            raise FileNotFoundError(f"Файл изображения не найден: {path}")

                    if len(image_paths) == 1:
                        logger.info(f"Отправка одного файла в {username}: {image_paths[0]}")
                        input_file = await self.client.upload_file(image_paths[0])
                        result = await self.client.send_file(
                            channel,
                            file=input_file,
                            caption=message,
                            parse_mode=None,
                            schedule=schedule
                        )
                        logger.info(f"Один файл отправлен, результат: {result}")
                        if result and result.message != message:
                            logger.warning(f"Подпись не отображена для {username}, ожидалось: {message}, получено: {result.message}")
                            await self.client.send_message(
                                channel,
                                message=message,
                                parse_mode=None,
                                schedule=schedule
                            )
                            logger.info(f"Текст отправлен отдельно в {username}")
                    else:
                        media: List[InputMediaUploadedPhoto] = []
                        for i, path in enumerate(image_paths):
                            logger.info(f"Загрузка изображения {i+1}/{len(image_paths)}: {path}")
                            input_file = await self.client.upload_file(path)
                            media_item = InputMediaUploadedPhoto(file=input_file)
                            if i == 0:
                                media_item.caption = message
                                media_item.parse_mode = None
                            media.append(media_item)

                        logger.info(f"Отправка группы медиа в {username}: {image_paths}")
                        result = await self.client.send_file(
                            channel,
                            file=media,
                            schedule=schedule
                        )
                        logger.info(f"Группа медиа отправлена, результат: {result}")
                        if result and isinstance(result, list) and result[0].message != message:
                            logger.warning(f"Подпись не отображена для {username}, ожидалось: {message}, получено: {result[0].message}")
                            await self.client.send_message(
                                channel,
                                message=message,
                                parse_mode=None,
                                schedule=schedule
                            )
                            logger.info(f"Текст отправлен отдельно в {username}")
                else:
                    logger.info(f"Отправка сообщения в {username}: {message}")
                    result = await self.client.send_message(
                        channel,
                        message=message,
                        parse_mode=None,
                        schedule=schedule
                    )
                    logger.info(f"Сообщение отправлено, результат: {result}")
                logger.info(f"Пост успешно отправлен в {username} (запланировано: {schedule is not None})")
            except Exception as e:
                failed_chats.append(username)
                logger.error(f"Не удалось отправить пост в {username}: {str(e)}")
                logger.error(f"Тип ошибки: {type(e).__name__}")

        if failed_chats:
            raise RuntimeError(f"Не удалось отправить пост в следующие чаты: {', '.join(failed_chats)}")

        return True

class PhoneRequest(BaseModel):
    phone: str
    login: str
    account_id: Optional[str] = None

class CodeRequest(BaseModel):
    code: str
    password: str = None

class VerifyCodeRequest(BaseModel):
    phone: str
    code: str
    password: Optional[str] = None
    login: str

API_ID: int = 29543259
API_HASH: str = 'faf53d8b03d60fc9dd19ce920971d67a'
GO_BACKEND_URL: str = "http://app:8080"

async def check_user_ban_and_forbidden_words(account_id: str, title: str, description: str, token: str) -> Tuple[bool, List[str]]:
    async with httpx.AsyncClient() as client:
        # Проверка статуса бана
        user_response = await client.get(
            f"{GO_BACKEND_URL}/api/user/{account_id}",
            headers={"Authorization": f"Bearer {token}"}
        )
        if user_response.status_code != 200:
            raise HTTPException(status_code=500, detail="Не удалось получить данные пользователя")
        user_data = user_response.json()
        if user_data.get("is_banned", False):
            raise HTTPException(status_code=403, detail="Пользователь заблокирован")

        # Проверка запрещенных слов
        check_response = await client.post(
            f"{GO_BACKEND_URL}/api/check_forbidden_words",
            json={"text": f"{title} {description}"},
            headers={"Authorization": f"Bearer {token}"}
        )
        if check_response.status_code != 200:
            raise HTTPException(status_code=500, detail=f"Не удалось проверить запрещенные слова: {check_response.text}")

        try:
            check_data = check_response.json()
        except ValueError:
            logger.error(f"Неверный JSON-ответ от проверки запрещенных слов: {check_response.text}")
            raise HTTPException(status_code=500, detail="Неверный ответ от проверки запрещенных слов")

        if check_data is None:
            logger.error("Получен пустой ответ от проверки запрещенных слов")
            forbidden_words = []
        else:
            forbidden_words = check_data.get("forbidden_words", [])
            if forbidden_words is None:
                logger.warning(f"forbidden_words имеет значение None в ответе: {check_data}")
                forbidden_words = []

        # Логирование для отладки
        logger.info(f"Результат проверки запрещенных слов: {forbidden_words}")

        if forbidden_words:
            # Сообщаем о попытке использования запрещенных слов
            await client.post(
                f"{GO_BACKEND_URL}/api/report_forbidden_words_attempt",
                json={"account_id": account_id, "forbidden_words": forbidden_words},
                headers={"Authorization": f"Bearer {token}"}
            )
        return len(forbidden_words) == 0, forbidden_words

@app.post("/api/telegram/request_code")
async def request_code(request: PhoneRequest) -> Dict[str, str]:
    auth = TelegramAuth(API_ID, API_HASH)
    if not await auth.send_code(request.phone):
        logger.error(f"Не удалось отправить код для телефона {request.phone}")
        raise HTTPException(status_code=400, detail="Не удалось отправить код")

    sessions[request.phone] = auth
    logger.info(f"Код успешно отправлен для телефона {request.phone}")
    return {"status": "Код отправлен", "message": "Код успешно отправлен"}

@app.post("/api/telegram/verify_code")
async def verify_code(request: VerifyCodeRequest, authorization: Optional[str] = Header(None)) -> Dict[str, str]:
    if request.phone not in sessions:
        logger.error(f"Сессия не найдена для телефона {request.phone}")
        raise HTTPException(status_code=404, detail="Сессия не найдена. Сначала запросите код.")

    if not authorization or not authorization.startswith("Bearer "):
        logger.error("Отсутствует или неверный заголовок Authorization")
        raise HTTPException(status_code=401, detail="Отсутствует или неверный токен")

    token = authorization.replace("Bearer ", "")
    auth = sessions[request.phone]
    try:
        if not await auth.sign_in(request.code, request.password):
            logger.error(f"Не удалось войти для телефона {request.phone}")
            raise HTTPException(status_code=401, detail="Неверный код или пароль")

        me = await auth.client.get_me()
        if not isinstance(me, User):
            logger.error(f"Не удалось получить информацию о пользователе для телефона {request.phone}")
            raise HTTPException(status_code=500, detail="Не удалось получить информацию о пользователе")

        logger.info(f"Успешный вход для телефона {request.phone}, пользователь: {me.username}")
        return {
            "status": "Успех",
            "message": "Авторизация прошла успешно",
            "username": me.username or ""
        }
    except ValueError as e:
        logger.error(f"Требуется пароль для телефона {request.phone}: {str(e)}")
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        logger.error(f"Не удалось проверить код для телефона {request.phone}: {str(e)}")
        raise HTTPException(status_code=400, detail=f"Не удалось проверить код: {str(e)}")

async def get_channel_info(client: TelegramClient, channel_id: int) -> Tuple[str, List[str]]:
    try:
        channel = await client.get_entity(PeerChannel(channel_id))
        title = channel.title

        usernames = []
        if hasattr(channel, 'usernames') and channel.usernames:
            usernames = [u.username for u in channel.usernames if u.username]
        elif hasattr(channel, 'username') and channel.username:
            usernames = [channel.username]

        if not usernames:
            usernames = [f"channel_{channel.id}"]
            logger.info(f"Канал {title} не имеет имени пользователя, используется ID: {channel.id}")

        return title, usernames
    except Exception as e:
        logger.error(f"Ошибка получения информации о канале с channel_id {channel_id}: {str(e)}")
        return "", []

@app.post("/api/telegram/channels")
async def get_channels(request: PhoneRequest, authorization: Optional[str] = Header(None)) -> Dict[str, Any]:
    if not authorization or not authorization.startswith("Bearer "):
        logger.error("Отсутствует или неверный заголовок Authorization")
        raise HTTPException(status_code=401, detail="Отсутствует или неверный токен")

    token = authorization.replace("Bearer ", "")

    auth = sessions.get(request.phone)
    if not auth:
        logger.error(f"Сессия не найдена для телефона {request.phone}")
        raise HTTPException(status_code=404, detail="Сессия не найдена. Сначала выполните авторизацию.")

    if not await auth.client.is_user_authorized():
        logger.error(f"Сессия не авторизована для телефона {request.phone}")
        await auth.client.disconnect()
        del sessions[request.phone]
        raise HTTPException(status_code=403, detail="Пользователь не авторизован. Сначала запросите код.")

    if not request.account_id:
        logger.error(f"Отсутствует account_id для телефона {request.phone}")
        raise HTTPException(status_code=400, detail="account_id обязателен для получения каналов")

    try:
        channels = await auth.get_channels()
        result: List[Dict] = []
        channels_to_save: List[Dict] = []

        for item in channels:
            title, usernames = await get_channel_info(auth.client, item['id'])
            if title:
                main_username = usernames[0] if usernames else f"channel_{item['id']}"
                channel_data = {
                    'title': title,
                    'main_username': main_username
                }
                result.append(channel_data)
                channels_to_save.append({
                    'title': title,
                    'main_username': main_username,
                    'social_id': main_username
                })

        if channels_to_save:
            async with httpx.AsyncClient() as http_client:
                existing_links_response = await http_client.get(
                    f"{GO_BACKEND_URL}/api/links",
                    params={"user_id": request.account_id, "platform": "telegram"},
                    headers={"Authorization": f"Bearer {token}"}
                )
                logger.info(f"Ответ на запрос существующих ссылок: status={existing_links_response.status_code}, body={existing_links_response.text}")
                existing_social_ids = set()
                if existing_links_response.status_code == 200:
                    existing_links = existing_links_response.json().get("links", [])
                    existing_social_ids = {link["social_id"] for link in existing_links}
                else:
                    logger.warning(f"Не удалось получить существующие ссылки: {existing_links_response.text}")

                new_channels = [
                    channel for channel in channels_to_save
                    if channel["social_id"] not in existing_social_ids
                ]

                if new_channels:
                    save_response = await http_client.post(
                        f"{GO_BACKEND_URL}/api/links",
                        json={
                            "user_id": request.account_id,
                            "platform": "telegram",
                            "channels": new_channels
                        },
                        headers={"Authorization": f"Bearer {token}"}
                    )
                    logger.info(f"Ответ на сохранение ссылок: status={save_response.status_code}, body={save_response.text}")
                    if save_response.status_code != 200:
                        logger.error(f"Не удалось сохранить каналы в ссылки: {save_response.text}")
                        raise HTTPException(status_code=500, detail=f"Не удалось сохранить каналы в базу данных: {save_response.text}")

        logger.info(f"Успешно получено {len(result)} каналов для телефона {request.phone}, сохранено {len(new_channels)} новых каналов")
        return {
            "status": "успех",
            "channels": json.loads(json.dumps(result, ensure_ascii=False))
        }
    except RuntimeError as e:
        logger.error(f"Ошибка авторизации для телефона {request.phone}: {str(e)}")
        raise HTTPException(status_code=403, detail=f"Ошибка авторизации: {str(e)}")
    except Exception as e:
        logger.error(f"Внутренняя ошибка сервера для телефона {request.phone}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Внутренняя ошибка сервера: {str(e)}")

@app.post("/api/telegram/create_post")
async def create_post(
    phone: str = Form(...),
    chat_usernames: str = Form(...),
    title: str = Form(...),
    description: str = Form(...),
    schedule_date: str = Form(None),
    images: List[UploadFile] = File(None),
    authorization: Optional[str] = Header(None),
    account_id: str = Form(...)
) -> Dict[str, str]:
    if not authorization or not authorization.startswith("Bearer "):
        logger.error("Отсутствует или неверный заголовок Authorization")
        raise HTTPException(status_code=401, detail="Отсутствует или неверный токен")

    token = authorization.replace("Bearer ", "")

    if phone not in sessions:
        logger.error(f"Сессия не найдена для телефона {phone}")
        raise HTTPException(status_code=404, detail="Сессия не найдена. Сначала выполните авторизацию.")

    auth = sessions[phone]
    logger.info(f"Создание поста для телефона {phone}")
    logger.info(f"Получен заголовок: {title}")
    logger.info(f"Получено описание: {description}")

    # Проверка бана и запрещенных слов
    is_allowed, forbidden_words = await check_user_ban_and_forbidden_words(account_id, title, description, token)
    if not is_allowed:
        raise HTTPException(status_code=400, detail=f"Пост содержит запрещенные слова: {', '.join(forbidden_words)}")

    try:
        usernames = json.loads(chat_usernames)
        if not isinstance(usernames, list):
            raise ValueError("chat_usernames должен быть списком")
        logger.info(f"Получены chat_usernames: {usernames}")
    except Exception as e:
        logger.error(f"Неверный формат chat_usernames: {str(e)}")
        raise HTTPException(status_code=400, detail=f"Неверный формат chat_usernames: {str(e)}")

    logger.info(f"Получены изображения: {[image.filename for image in images] if images else 'Нет изображений'}")
    logger.info(f"Получена дата планирования: {schedule_date}")

    schedule_datetime: datetime = None
    if schedule_date:
        try:
            cleaned_schedule_date = schedule_date.replace("Z", "").strip()
            if cleaned_schedule_date.endswith("+00:00"):
                cleaned_schedule_date = cleaned_schedule_date[:-6]
            cleaned_schedule_date += "+00:00"
            schedule_datetime = datetime.fromisoformat(cleaned_schedule_date)
            schedule_datetime = schedule_datetime.astimezone(pytz.UTC)
            current_time = datetime.now(pytz.UTC)
            logger.info(f"Разобранная schedule_datetime (UTC): {schedule_datetime}")
            logger.info(f"Текущее время UTC: {current_time}")
            logger.info(f"Разница во времени (секунды): {(schedule_datetime - current_time).total_seconds()}")
            if schedule_datetime <= current_time:
                logger.warning("Дата планирования в прошлом или сейчас, отправка немедленно")
                schedule_datetime = None
        except ValueError as e:
            logger.error(f"Неверный формат даты планирования: {str(e)}")
            raise HTTPException(status_code=400, detail=f"Неверный формат даты и времени: {str(e)}")

    image_paths: List[str] = []
    try:
        if images:
            for image in images:
                if image and image.filename:
                    with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
                        temp_file.write(await image.read())
                        image_paths.append(temp_file.name)
                        logger.info(f"Сохранен временный файл изображения: {temp_file.name}")

        if schedule_datetime:
            draft = {
                "phone": phone,
                "chat_usernames": usernames,
                "title": title,
                "description": description,
                "image_paths": image_paths,
                "schedule": schedule_datetime,
                "created_at": datetime.now(pytz.UTC)
            }
            drafts.append(draft)
            logger.info(f"Черновик сохранен для отложенного поста: {draft}")
            return {"status": "успех", "message": "Пост успешно отложен"}
        else:
            logger.info("Нет даты планирования или она в прошлом, отправка поста немедленно")
            await auth.create_post(
                usernames,
                title,
                description,
                image_paths if image_paths else None,
                None
            )
            logger.info(f"Пост успешно создан для телефона {phone}")
            return {"status": "успех", "message": "Пост успешно опубликован"}
    except RuntimeError as e:
        logger.error(f"Ошибка авторизации для телефона {phone}: {str(e)}")
        raise HTTPException(status_code=403, detail=f"Ошибка авторизации: {str(e)}")
    except Exception as e:
        logger.error(f"Внутренняя ошибка сервера для телефона {phone}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Внутренняя ошибка сервера: {str(e)}")
    finally:
        if not schedule_datetime and image_paths:
            for path in image_paths:
                logger.info(f"Попытка удалить временный файл (немедленный пост): {path}")
                try:
                    if os.path.exists(path):
                        os.unlink(path)
                        logger.info(f"Удален временный файл: {path}")
                    else:
                        logger.warning(f"Временный файл не найден: {path}")
                except Exception as e:
                    logger.error(f"Не удалось удалить временный файл {path}: {str(e)}")

@app.post("/api/telegram/save_draft")
async def save_draft(
    phone: str = Form(...),
    chat_usernames: str = Form(...),
    title: str = Form(...),
    description: str = Form(...),
    schedule_date: str = Form(None),
    images: List[UploadFile] = File(None),
    authorization: Optional[str] = Header(None),
    account_id: str = Form(...)
) -> Dict[str, str]:
    if not authorization or not authorization.startswith("Bearer "):
        logger.error("Отсутствует или неверный заголовок Authorization")
        raise HTTPException(status_code=401, detail="Отсутствует или неверный токен")

    token = authorization.replace("Bearer ", "")

    # Проверка бана и запрещенных слов
    is_allowed, forbidden_words = await check_user_ban_and_forbidden_words(account_id, title, description, token)
    if not is_allowed:
        raise HTTPException(status_code=400, detail=f"Пост содержит запрещенные слова: {', '.join(forbidden_words)}")

    try:
        usernames = json.loads(chat_usernames)
        if not isinstance(usernames, list):
            raise ValueError("chat_usernames должен быть списком")
        logger.info(f"Получены chat_usernames для черновика: {usernames}")
    except Exception as e:
        logger.error(f"Неверный формат chat_usernames: {str(e)}")
        raise HTTPException(status_code=400, detail=f"Неверный формат chat_usernames: {str(e)}")

    schedule_datetime: datetime = None
    if schedule_date:
        try:
            schedule_datetime = datetime.fromisoformat(schedule_date.replace("Z", "+00:00"))
            schedule_datetime = schedule_datetime.astimezone(pytz.UTC)
            if schedule_datetime < datetime.now(pytz.UTC):
                raise ValueError("Дата планирования должна быть в будущем")
            logger.info(f"Разобранная schedule_datetime для черновика: {schedule_datetime}")
        except ValueError as e:
            logger.error(f"Неверный формат даты планирования или дата в прошлом: {str(e)}")
            raise HTTPException(status_code=400, detail=f"Неверный формат времени или дата в прошлом: {str(e)}")

    image_paths: List[str] = []
    if images:
        for image in images:
            if image:
                with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
                    temp_file.write(await image.read())
                    image_paths.append(temp_file.name)
                    logger.info(f"Сохранен временный файл изображения: {temp_file.name}")

    draft = {
        "phone": phone,
        "chat_usernames": usernames,
        "title": title,
        "description": description,
        "image_paths": image_paths,
        "schedule": schedule_datetime,
        "created_at": datetime.now(pytz.UTC)
    }
    drafts.append(draft)
    logger.info(f"Черновик сохранен: {draft}")
    return {"status": "успех", "message": "Черновик успешно сохранен"}

async def publish_drafts():
    while True:
        current_time = datetime.now(pytz.UTC)
        logger.info(f"Проверка черновиков в {current_time}, всего черновиков: {len(drafts)}")
        for draft in drafts[:]:
            if draft["schedule"] and current_time >= draft["schedule"]:
                logger.info(f"Публикация черновика, запланированного на {draft['schedule']}")
                logger.info(f"Детали черновика: {draft}")
                try:
                    auth = sessions.get(draft["phone"])
                    if not auth:
                        logger.warning(f"Сессия не найдена для телефона {draft['phone']}, черновик пропущен")
                        drafts.remove(draft)
                        continue

                    for path in draft["image_paths"]:
                        if not os.path.exists(path):
                            raise FileNotFoundError(f"Файл изображения не найден: {path}")

                    await auth.create_post(
                        draft["chat_usernames"],
                        draft["title"],
                        draft["description"],
                        draft["image_paths"] if draft["image_paths"] else None,
                        None
                    )
                    logger.info(f"Черновик успешно опубликован для {draft['phone']}")
                    drafts.remove(draft)
                except Exception as e:
                    logger.error(f"Не удалось опубликовать черновик: {str(e)}")
                    logger.error(f"Тип ошибки: {type(e).__name__}")
                    drafts.remove(draft)
                finally:
                    for path in draft["image_paths"]:
                        logger.info(f"Попытка удалить временный файл: {path}")
                        try:
                            if os.path.exists(path):
                                os.unlink(path)
                                logger.info(f"Удален временный файл: {path}")
                            else:
                                logger.warning(f"Временный файл не найден: {path}")
                        except Exception as e:
                            logger.error(f"Не удалось удалить временный файл {path}: {str(e)}")
            else:
                logger.info(f"Черновик не готов к публикации: {draft['schedule']} (текущее время: {current_time})")
        await asyncio.sleep(60)

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(publish_drafts())
    logger.info("Приложение запущено, задача publish_drafts выполняется")

@app.on_event("shutdown")
async def shutdown_event():
    for phone, auth in sessions.items():
        await auth.client.disconnect()
    logger.info("Все клиенты Telegram отключены")

@app.post("/api/telegram/logout_telegram")
async def logout_telegram(request: PhoneRequest, authorization: Optional[str] = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Отсутствует или неверный токен")
    token = authorization.replace("Bearer ", "")
    auth = sessions.get(request.phone)
    if auth:
        await auth.client.disconnect()
        del sessions[request.phone]
    return {"status": "Успех", "message": "Вы успешно вышли из Telegram"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
