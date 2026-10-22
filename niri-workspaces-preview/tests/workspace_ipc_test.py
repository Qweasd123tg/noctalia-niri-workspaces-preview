"""Run the embedded IPC client against a mock socket without changing desktop state."""
import io
import json
import os
from pathlib import Path
import re
import socket
import sys
from unittest.mock import patch

source = Path("widget.luau").read_text()
program = re.search(r"local FOCUS_WORKSPACE_IPC = \[\[(.*?)\]\]", source, re.S).group(1)


class Client:
    response = b'{"Ok":"Handled"}\n'

    def __enter__(self):
        return self

    def __exit__(self, *_):
        pass

    def settimeout(self, timeout):
        assert timeout == 2

    def connect(self, path):
        assert path == "/mock/niri.sock"

    def sendall(self, message):
        assert message.endswith(b"\n")
        self.request = json.loads(message)

    def makefile(self, mode):
        assert mode == "rb"
        return io.BytesIO(self.response)


client = Client()
with patch.object(socket, "socket", return_value=client), patch.dict(os.environ, {"NIRI_SOCKET": "/mock/niri.sock"}), patch.object(sys, "argv", ["ipc", "21"]):
    exec(compile(program, "workspace-ipc", "exec"), {})
assert client.request == {"Action": {"FocusWorkspace": {"reference": {"Id": 21}}}}
client.response = b'{"Err":"unavailable"}\n'
with patch.object(socket, "socket", return_value=client), patch.dict(os.environ, {"NIRI_SOCKET": "/mock/niri.sock"}), patch.object(sys, "argv", ["ipc", "21"]):
    try:
        exec(compile(program, "workspace-ipc", "exec"), {})
    except SystemExit as error:
        assert str(error) == "unavailable"
    else:
        raise AssertionError("IPC errors must not be silently treated as success")
print("workspace IPC tests passed")
