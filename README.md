# CloudMigrationHU

## Authors

- [attilamacskasy](https://github.com/attilamacskasy)
- [peterkarpati0](https://github.com/peterkarpati0)

## Purpose

The **CloudMigrationHU** project aims to automate the setup and configuration of Windows Server 2022 domain controllers, specifically DC01 and DC02. The project provides PowerShell scripts to streamline tasks such as setting computer names, configuring IP addresses, and applying common server settings, ensuring a consistent and efficient deployment process.

## Architecture Diagram

```mermaid
graph TD;
    subgraph Network
        DC01["<img src='data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyODQuODg2IiBoZWlnaHQ9IjM4OS42ODgiIHZpZXdCb3g9IjAgMCA3NS4zNzYgMTAzLjEwNSI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJBIiB4MT0iODMuODM5IiB5MT0iMjAwLjM5MyIgeDI9IjgzLjQ3IiB5Mj0iMTI3LjI5NSIgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiPjxzdG9wIG9mZnNldD0iMCIgc3RvcC1jb2xvcj0iIzA2NzdmYyIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzhmY2FmZSIvPjwvbGluZWFyR3JhZGllbnQ+PGxpbmVhckdyYWRpZW50IGlkPSJCIiB4MT0iMTExLjI2NiIgeTE9IjIwNi4zMDQiIHgyPSIxMTEuNDgiIHkyPSIxMTguMzcyIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+PHN0b3Agb2Zmc2V0PSIwIiBzdG9wLWNvbG9yPSIjMDUyMzlhIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjOTFiY2Y4Ii8+PC9saW5lYXJHcmFkaWVudD48bGluZWFyR3JhZGllbnQgaWQ9IkMiIHgxPSIxMDMuMDgyIiB5MT0iMTM2Ljg5IiB4Mj0iMTAzLjE5NCIgeTI9IjEwNy42MjQiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj48c3RvcCBvZmZzZXQ9IjAiIHN0b3AtY29sb3I9IiNhOGRlZmUiLz48c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiMxMmE3ZmMiLz48L2xpbmVhckdyYWRpZW50PjxsaW5lYXJHcmFkaWVudCBpZD0iRCIgeDE9IjEyMS45NjIiIHkxPSIxNzIuMTE1IiB4Mj0iMTIxLjczNCIgeTI9IjEzNi40MTIiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj48c3RvcCBvZmZzZXQ9IjAiIHN0b3AtY29sb3I9IiNmZWNiNDUiLz48c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiNmZTY3MDYiLz48L2xpbmVhckdyYWRpZW50PjwvZGVmcz48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtNzIuNTgzIC0xMDUuNzM4KSI+PHBhdGggZD0iTTEyOS41MiAxODcuNDY4bC0zNi45NjMgMTkuNjY4VjEzNy4yMWwzNi45NjMtMTkuOTM4eiIgZmlsbD0idXJsKCNCKSIvPjxwYXRoIGQ9Ik05Mi41NTcgMjA3LjEzNkw3NC4wODMgMTk2LjkzVjEyNy4xbDE4LjQ3NCAxMC4xMSIgZmlsbD0idXJsKCNBKSIvPjxwYXRoIGQ9Ik0xMjkuNTIgMTE3LjI3Mkw5Mi41NTcgMTM3LjIxIDc0LjA4MyAxMjcuMWwzNi44NDgtMTkuNjYzeiIgZmlsbD0idXJsKCNDKSIvPjxwYXRoIGQ9Ik03OS4zNTUgMTUwLjgzdjEuMzIybDYuNjMgMy42Mzh2LTEuMzIyem0wIDYuNjczdjEuMzIybDYuNjMgMy42Mzh2LTEuMzIyeiIgZG9taW5hbnQtYmFzZWxpbmU9ImF1dG8iIGZpbGw9IiNmZmYiLz48cGF0aCBkPSJNOTIuNTU3IDEzNy4yMWwzNi45NjMtMTkuOTM4em0wIDY5LjkyNlYxMzcuMjFMNzQuMDgzIDEyNy4xbTE4LjQ3NCA4MC4wMzZMNzQuMDgzIDE5Ni45M1YxMjcuMWwzNi44NDgtMTkuNjYzIDE4LjU5IDkuODM2djcwLjE5NnoiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLXdpZHRoPSIzIi8+PHBhdGggZD0iTTEyMS43MzIgMTI5LjI4N2wtMjYuMjEgNDYuNDg0aDUyLjQzNnoiIGRvbWluYW50LWJhc2VsaW5lPSJhdXRvIiBmaWxsPSIjZmZmIi8+PHBhdGggZD0iTTEyMS43MzQgMTM2LjQxMmwyMC4yMzIgMzUuODZoLTQwLjQ1eiIgZG9taW5hbnQtYmFzZWxpbmU9ImF1dG8iIGZpbGw9InVybCgjRCkiLz48L2c+PC9zdmc+' width='10'/> DC01"]
        DC02["<img src='download.svg' width='10'/> DC02"]
    end
    
```



