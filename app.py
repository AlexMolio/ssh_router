from pathlib import Path
import re
import subprocess
import os
import platform

from textual.app import App, ComposeResult
from textual.widgets import ListView, ListItem, Label, Input, Button
from textual import events
from textual.screen import Screen
from textual.widgets import Input as TextualInput
from textual.containers import Horizontal, Center

SSH_CONFIG_PATH = Path.home() / ".ssh" / "config"

def get_ssh_hosts(config_path):
    hosts = []
    if not config_path.exists():
        return hosts
    with open(config_path, "r") as file:
        for line in file:
            line = line.strip()
            match = re.match(r"^Host\s+(.+)", line)
            if match:
                host = match.group(1)
                if "*" not in host and "?" not in host:
                    hosts.append(host)
    return hosts

class AddHostScreen(Screen):
    CSS = """
    #add-host-label {
        background: transparent;
        padding: 1 1;
        text-style: bold;
    }
    #add-host-center {
        align: center middle;
        width: 100%;
        height: 100%;
    }
    TextualInput, Button, Label {
        width: 80%;
        margin: 1 0;
        align: center middle;
    }
    Button {
        width: 40%;
    }
    """

    def compose(self) -> ComposeResult:
        with Center(id="add-host-center"):
            yield Label("Add new host", id="add-host-label")
            yield TextualInput(placeholder="Name", id="host-name")
            yield TextualInput(placeholder="IP/URL", id="host-ip")
            yield TextualInput(placeholder="User", id="host-user")
            yield Button("Save", id="save-host")

    async def on_key(self, event: events.Key) -> None:
        if event.key == "down":
            current_focus = self.focused
            if current_focus and current_focus.id in ["host-name", "host-ip", "host-user", "save-host"]:
                next_id = {"host-name": "host-ip", "host-ip": "host-user", "host-user": "save-host", "save-host": "host-name"}.get(current_focus.id)
                if next_id:
                    self.query_one(f"#{next_id}").focus()
        elif event.key == "up":
            current_focus = self.focused
            if current_focus and current_focus.id in ["host-name", "host-ip", "host-user", "save-host"]:
                prev_id = {"host-ip": "host-name", "host-user": "host-ip", "save-host": "host-user", "host-name": "save-host"}.get(current_focus.id)
                if prev_id:
                    self.query_one(f"#{prev_id}").focus()

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "save-host":
            name = self.query_one("#host-name").value
            ip_url = self.query_one("#host-ip").value
            user = self.query_one("#host-user").value
            config_path = Path.home() / ".ssh" / "config"
            with open(config_path, "a") as file:
                file.write(f"\nHost {name}\n    HostName {ip_url}\n    User {user}\n")
            await self.app.refresh_hosts()
            self.app.pop_screen()

class SSHSelectorApp(App):
    CSS = """
    Horizontal {
        layout: horizontal;
        align: left middle;
        height: auto;
        padding: 0 1;
    }
    ListView {
        border: round white;
        height: 80%;
        width: 100%;
        margin: 0 1;
        padding: 0 1;
        background: transparent;
    }
    Input {
        width: 80%;
        height: 3;
        border: round white;
        background: transparent;
    }
    Button {
        width: 20%;
        margin-left: 0;
        border: round white;
        background: transparent;
    }
    Label {
        color: white;
        background: transparent;
    }
    """

    def compose(self) -> ComposeResult:
        with Horizontal(id="search-bar"):
            yield Input(placeholder="Search hosts...", id="search-input")
            yield Button("Add Host", id="add-host-button")
        hosts = get_ssh_hosts(SSH_CONFIG_PATH)
        items = [ListItem(Label(host)) for host in hosts]
        yield ListView(*items, id="host-list")

    async def on_input_changed(self, event: Input.Changed) -> None:
        search_query = event.value.lower()
        hosts = get_ssh_hosts(SSH_CONFIG_PATH)
        filtered_hosts = [host for host in hosts if search_query in host.lower()]
        list_view = self.query_one(ListView)
        list_view.clear()
        for host in filtered_hosts:
            list_view.append(ListItem(Label(host)))

    async def on_list_view_selected(self, message: ListView.Selected) -> None:
        host = message.item.query_one(Label).renderable
        await self.action_quit()
        # os.execvp("ssh", ["ssh", host])
        # subprocess.run(["ssh", host])
        # subprocess.Popen(["ssh", host])

        if platform.system() == "Windows":
            # Windows Terminal (если установлен)
            subprocess.run(["powershell", "ssh", host], shell=True)
        elif platform.system() == "Darwin":
            # macOS – Terminal.app через AppleScript
            os.system(f'''osascript -e 'tell application "Terminal" to do script "ssh {host}"' ''')
        else:
            print("Эта ОС пока не поддерживается этим скриптом")

    async def on_mount(self) -> None:
        search_input = self.query_one("#search-input")
        search_input.focus()

    async def on_key(self, event: events.Key) -> None:
        list_view = self.query_one(ListView)
        if event.key == "q":
            await self.action_quit()
        elif event.key == "down":
            list_view.focus()
        elif event.key == "up":
            if self.focused == list_view and list_view.index == 0:
                search_input = self.query_one("#search-input")
                search_input.focus()
        elif self.focused == list_view and len(event.key) == 1:
            search_input = self.query_one("#search-input")
            search_input.focus()
        elif event.key == "backspace" and self.focused == list_view:
            search_input = self.query_one("#search-input")
            search_input.focus()
        elif event.key == "escape":
            await self.action_quit()
        elif event.key == "ctrl+n":
            self.push_screen(AddHostScreen())

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "add-host-button":
            self.push_screen(AddHostScreen())

    async def refresh_hosts(self) -> None:
        list_view = self.query_one(ListView)
        hosts = get_ssh_hosts(SSH_CONFIG_PATH)
        list_view.clear()
        for host in hosts:
            list_view.append(ListItem(Label(host)))

if __name__ == "__main__":
    SSHSelectorApp().run()
