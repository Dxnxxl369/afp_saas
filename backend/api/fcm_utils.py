import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
import os
import logging

logger = logging.getLogger(__name__)

def initialize_firebase_app():
    """
    Initializes the Firebase Admin SDK if it hasn't been initialized already.
    Uses the service account key specified in Django settings.
    """
    if not firebase_admin._apps:
        try:
            cred_path = settings.FIREBASE_ADMIN_CREDENTIALS_PATH
            if not os.path.exists(cred_path):
                logger.error(f"Firebase service account key not found at: {cred_path}")
                return False
            
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized successfully.")
            return True
        except Exception as e:
            logger.error(f"Error initializing Firebase Admin SDK: {e}")
            return False
    return True # Already initialized

def send_fcm_notification(fcm_token, title, body, data=None):
    """
    Sends a push notification to a specific device using its FCM token.
    
    Args:
        fcm_token (str): The FCM registration token of the device.
        title (str): The title of the notification.
        body (str): The body text of the notification.
        data (dict, optional): A dictionary of custom key-value pairs to send as data payload.
                               These are not displayed to the user directly but can be handled by the app.
                               Defaults to None.
    Returns:
        bool: True if the message was sent successfully, False otherwise.
        str: The message ID if successful, or an error message if failed.
    """
    if not initialize_firebase_app():
        return False, "Firebase Admin SDK not initialized."

    # --- NUEVO: Add Android specific configuration for heads-up notifications ---
    android_config = messaging.AndroidConfig(
        priority='high',
        notification=messaging.AndroidNotification(
            channel_id='high_importance_channel', # Must match channel ID in Flutter's main.dart
        ),
    )

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data,
        token=fcm_token,
        android=android_config, # <--- NUEVO
    )

    try:
        response = messaging.send(message)
        logger.info(f"Successfully sent FCM message: {response}")
        return True, response
    except Exception as e:
        logger.error(f"Error sending FCM message: {e}")
        return False, str(e)