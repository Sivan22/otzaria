import os
import json

from pyluach import dates

from mitmachim import MitmachimClient
from yemot import split_and_send


def heb_date() -> str:
    today = dates.HebrewDate.today()
    date_str = today.hebrew_date_string()
    return date_str


date_str = heb_date()
RELEASE_TAG = os.getenv("RELEASE_TAG", "Unknown")
RELEASE_NAME = os.getenv("RELEASE_NAME", "No Name")
RELEASE_BODY = os.getenv("RELEASE_BODY", "")
RELEASE_URL = os.getenv("RELEASE_URL", "")
GITHUB_EVENT_PATH = os.getenv("GITHUB_EVENT_PATH")
username = os.getenv("USER_NAME")
password = os.getenv("PASSWORD")
yemot_token = os.getenv("TOKEN_YEMOT")
asset_links = []
if GITHUB_EVENT_PATH:
    with open(GITHUB_EVENT_PATH, "r", encoding="utf-8") as f:
        event_data = json.load(f)
        assets = event_data.get("release", {}).get("assets", [])
        for asset in assets:
            asset_links.append(f"[{asset['name']}]({asset['browser_download_url']})")
date_yemot = f"עדכון {date_str}\n"
yemot_path = "ivr2:/2"
tzintuk_list_name = "software update"
yemot_message = f"עדכון {date_str}\nשחרור {RELEASE_NAME}\nפרטים: {RELEASE_BODY}\n"
content_mitmachim = f"עדכון {date_str}\nשחרור {RELEASE_NAME}\nפרטים: {RELEASE_BODY}\n{RELEASE_URL}\nקבצים מצורפים:\n* {"\n* ".join(asset_links)}"

client = MitmachimClient(username.strip().replace(" ", "+"), password.strip())
if asset_links:
    try:
        client.login()
        topic_id = 87961
        client.send_post(content_mitmachim, topic_id)
    except Exception as e:
        print(e)
    finally:
        client.logout()

    try:
        split_and_send(yemot_message, date_yemot, yemot_token, yemot_path, tzintuk_list_name)
    except Exception as e:
        print(e)
