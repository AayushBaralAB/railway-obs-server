import os
import hmac
import hashlib
import base64
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs

USERNAME = os.environ.get("LOGIN_USERNAME", "admin")
PASSWORD = os.environ.get("LOGIN_PASSWORD", "change-me")
SECRET = os.environ.get("LOGIN_SECRET", "change-this-secret")

PORT = 9000


def make_token(username):
    data = username.encode()
    signature = hmac.new(
        SECRET.encode(),
        data,
        hashlib.sha256
    ).hexdigest()

    raw = f"{username}:{signature}".encode()
    return base64.urlsafe_b64encode(raw).decode()


def valid_token(token):
    try:
        raw = base64.urlsafe_b64decode(token.encode()).decode()
        username, signature = raw.split(":", 1)

        expected = hmac.new(
            SECRET.encode(),
            username.encode(),
            hashlib.sha256
        ).hexdigest()

        return (
            hmac.compare_digest(signature, expected)
            and username == USERNAME
        )

    except Exception:
        return False


LOGIN_PAGE = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Aayush Live - Login</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #111827, #1e3a8a);
            color: white;
        }

        .box {
            width: 380px;
            max-width: 92%;
            background: rgba(255,255,255,0.10);
            backdrop-filter: blur(15px);
            border: 1px solid rgba(255,255,255,0.15);
            border-radius: 20px;
            padding: 35px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.35);
        }

        .logo {
            text-align: center;
            font-size: 30px;
            font-weight: bold;
            margin-bottom: 5px;
        }

        .subtitle {
            text-align: center;
            color: #cbd5e1;
            margin-bottom: 30px;
        }

        label {
            display: block;
            margin-bottom: 8px;
            font-size: 14px;
            color: #e2e8f0;
        }

        input {
            width: 100%;
            padding: 13px;
            margin-bottom: 20px;
            border-radius: 10px;
            border: 1px solid #64748b;
            background: rgba(0,0,0,0.25);
            color: white;
            outline: none;
            font-size: 15px;
        }

        input:focus {
            border-color: #60a5fa;
        }

        button {
            width: 100%;
            padding: 13px;
            border: none;
            border-radius: 10px;
            background: #2563eb;
            color: white;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
        }

        button:hover {
            background: #1d4ed8;
        }

        .error {
            background: rgba(239,68,68,0.20);
            border: 1px solid rgba(239,68,68,0.40);
            padding: 10px;
            border-radius: 8px;
            margin-bottom: 18px;
            text-align: center;
        }

        .website {
            text-align: center;
            margin-top: 25px;
        }

        .website a {
            color: #93c5fd;
            text-decoration: none;
        }

        .website a:hover {
            text-decoration: underline;
        }
    </style>
</head>

<body>

<div class="box">

    <div class="logo">AAYUSH BARAL</div>

    <div class="subtitle">
        Virtual Studio
    </div>

    ERROR_PLACEHOLDER

    <form method="POST" action="/login">

        <label>Username</label>
        <input
            type="text"
            name="username"
            placeholder="Enter username"
            required
            autocomplete="username"
        >

        <label>Password</label>
        <input
            type="password"
            name="password"
            placeholder="Enter password"
            required
            autocomplete="current-password"
        >

        <button type="submit">
            LOGIN
        </button>

    </form>

    <div class="website">
        <a href="https://aayushbaral.com" target="_blank">
            Visit aayushbaral.com →
        </a>
    </div>

</div>

</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):

    def send_html(self, html, status=200):

        data = html.encode("utf-8")

        self.send_response(status)

        self.send_header(
            "Content-Type",
            "text/html; charset=utf-8"
        )

        self.send_header(
            "Content-Length",
            str(len(data))
        )

        self.end_headers()

        self.wfile.write(data)


    def do_GET(self):

        if self.path == "/check":

            cookie = self.headers.get("Cookie", "")

            token = ""

            for part in cookie.split(";"):

                part = part.strip()

                if part.startswith("auth="):
                    token = part[5:]

            if valid_token(token):

                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"OK")

            else:

                self.send_response(401)
                self.end_headers()

            return


        if self.path == "/logout":

            self.send_response(302)

            self.send_header(
                "Set-Cookie",
                "auth=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax"
            )

            self.send_header(
                "Location",
                "/"
            )

            self.end_headers()

            return


        self.send_html(
            LOGIN_PAGE.replace(
                "ERROR_PLACEHOLDER",
                ""
            )
        )


    def do_POST(self):

        if self.path != "/login":
            self.send_response(404)
            self.end_headers()
            return

        length = int(
            self.headers.get("Content-Length", 0)
        )

        body = self.rfile.read(length).decode()

        form = parse_qs(body)

        username = form.get(
            "username",
            [""]
        )[0]

        password = form.get(
            "password",
            [""]
        )[0]

        if (
            hmac.compare_digest(username, USERNAME)
            and hmac.compare_digest(password, PASSWORD)
        ):

            token = make_token(USERNAME)

            self.send_response(302)

            self.send_header(
                "Set-Cookie",
                f"auth={token}; Path=/; HttpOnly; SameSite=Lax"
            )

            self.send_header(
                "Location",
                "/vnc_auto.html"
            )

            self.end_headers()

        else:

            error = """
            <div class="error">
                Invalid username or password.
            </div>
            """

            self.send_html(
                LOGIN_PAGE.replace(
                    "ERROR_PLACEHOLDER",
                    error
                ),
                401
            )


server = HTTPServer(
    ("127.0.0.1", PORT),
    Handler
)

print(f"Login server running on {PORT}")

server.serve_forever()
