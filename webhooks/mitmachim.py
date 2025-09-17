import requests
from bs4 import BeautifulSoup
import re
import uuid


class MitmachimClient:
    def __init__(self, username, password):
        self.base_url = "https://mitmachim.top"
        self.session = requests.Session()
        self.username = username
        self.password = password
        self.csrf_token = None
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Gecko/20100101 Firefox/132.0",
            "Accept-Language": "he,he-IL;q=0.8,en-US;q=0.5,en;q=0.3",
        }

    @staticmethod
    def extract_csrf_token(html):
        def find_token_in_script(script_text):
            csrf_match = re.search(r'"csrf_token":"([^"]+)"', script_text)
            return csrf_match.group(1) if csrf_match else None

        soup = BeautifulSoup(html, "html.parser")
        script_tags = soup.find_all("script")
        for script in script_tags:
            if "csrf" in str(script):
                return find_token_in_script(str(script))
        return None

    def fetch_csrf_token(self):
        login_page = self.session.get(f"{self.base_url}/login", headers=self.headers)
        self.csrf_token = self.extract_csrf_token(login_page.text)

    def login(self):
        self.fetch_csrf_token()
        if not self.csrf_token:
            raise ValueError("Failed to fetch CSRF token")

        login_data = {
            "username": self.username,
            "password": self.password,
            "_csrf": self.csrf_token,
            "noscript": "false",
            "remember": "on",
        }
        login_headers = self.headers.copy()
        login_headers.update({
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "x-csrf-token": self.csrf_token,
        })

        response = self.session.post(f"{self.base_url}/login", headers=login_headers, data=login_data)
        if response.status_code != 200:
            raise ValueError(f"Login failed with status code {response.status_code}")
        print("Login successful")

    def send_post(self, content, topic_id, to_pid=None):
        post_url = f"{self.base_url}/api/v3/topics/{topic_id}"
        post_headers = self.headers.copy()
        post_headers.update({
            "Content-Type": "application/json; charset=utf-8",
            "x-csrf-token": self.csrf_token,
        })
        data = {
            "uuid": str(uuid.uuid4()),
            "tid": topic_id,
            "handle": "",
            "content": content,
            "toPid": to_pid,
        }
        response = self.session.post(post_url, json=data, headers=post_headers)
        return response.json()

    def logout(self):
        logout_url = f"{self.base_url}/logout"
        logout_headers = self.headers.copy()
        logout_headers.update({"x-csrf-token": self.csrf_token})
        response = self.session.post(logout_url, headers=logout_headers)
        if response.status_code == 200:
            print("Logout successful")
        else:
            print(f"Logout failed with status code {response.status_code}")
