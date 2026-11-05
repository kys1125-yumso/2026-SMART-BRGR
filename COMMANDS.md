# 에이전트 명령어 치트시트 (대회 당일용)

Windows PowerShell 기준. 프로젝트 폴더 안에서 실행.
외울 핵심은 딱 한 줄: `uv run ctf-solve --challenge challenges\<문제폴더> --no-submit -v`

---

## 0) 자리에 앉으면 한 번

```powershell
cd C:\Users\<사용자>\Desktop\ctf-agent
docker ps
. .\scripts\New-Chall.ps1     # 문제 폴더 한 줄 생성 helper 로드 (터미널마다 1회)
```
`docker ps`가 에러 없이 나오면 준비 완료. 에러 나면 Docker Desktop 먼저 실행.
새 터미널을 열 때마다 `. .\scripts\New-Chall.ps1` 를 한 번 쳐야 `New-Chall` 이 켜집니다.

---

## ★ 문제 폴더 한 줄 생성 (New-Chall)

입력은 **분야 + 설명** 두 개면 끝. 폴더 이름·파일 복사는 자동입니다.

```powershell
New-Chall web                         # 분야만 → 메모장 떠서 긴 지문 붙여넣고 저장·닫기. 최근 다운로드 자동 흡수
New-Chall web "로그인 우회해서 admin 되기"    # 짧은 지문은 한 줄로
New-Chall crypto "RSA n,e,c" .\a.txt      # 첨부파일 직접 지정
New-Chall web "설명" -Conn "http://10.1.2.3:8080"   # 인스턴스형(접속주소)
New-Chall web "설명" -Run                 # 만들고 바로 풀이 실행
```

자동으로 해주는 것:
- **폴더 이름**: `web-01`, `web-02`... 분야 기준 번호 자동 (직접 정하려면 `-Name for-99`)
- **첨부파일**: 가장 최근 **Downloads** 파일을 `distfiles\` 로 복사 (끄려면 `-NoFile`)
- **지문**: 짧으면 따옴표 안에, 길면 생략 → 메모장에 붙여넣고 저장하면 metadata에 자동 반영

> 지문은 **요약하지 말고 출제자 원문 그대로** 붙여넣으세요(힌트가 숨어 있음).
> 파일 자동 흡수를 쓸 땐 **문제 받자마자** 명령을 치세요(최근 다운로드 = 그 문제 파일).

생성 후 실행은 아래 1)번과 동일하게 `uv run ctf-solve ...`.

---

## 1) 파일형 문제 (20문항, 주력)

> 빠른 길은 위 **New-Chall** 한 줄(`New-Chall crypto "지문"`). 아래는 수동 방식(helper 없이).

```powershell
# (1) 문제 폴더 생성 — for-01 자리는 원하는 이름
Copy-Item -Recurse challenges\_example-file challenges\for-01

# (2) 받은 문제 파일을 distfiles 로 복사
Copy-Item C:\Users\<사용자>\Downloads\problem.zip challenges\for-01\distfiles\

# (3) metadata.yml 편집: category(분야), description(설명) 채우기
notepad challenges\for-01\metadata.yml

# (4) 실행
uv run ctf-solve --challenge challenges\for-01 --no-submit -v
```
→ `FLAG FOUND: DAKER{...}` 나오면 DAKER 웹 폼에 수동 제출.

**category 값**: web | pwn | forensics | reverse | crypto | misc

---

## 2) 인스턴스형 문제 (5문항)

```powershell
Copy-Item -Recurse challenges\_example-instance challenges\web-01
notepad challenges\web-01\metadata.yml
# metadata.yml 의 connection_info 에 접속주소 붙여넣기:
#   웹이면  http://10.x.x.x:12345
#   pwn이면 "nc 10.x.x.x 12345"
uv run ctf-solve --challenge challenges\web-01 --no-submit -v
```
※ 노트북이 **대회 WiFi**에 연결돼 있어야 인스턴스에 접속됨.

---

## 3) 멈추기

해당 터미널에서 **Ctrl + C**.
(에이전트는 스스로 포기하지 않음 → 어려운 문제는 적당히 끊고 넘어갈 것.)

---

## 4) 여러 문제 동시에

PowerShell 창을 **새로 하나 더 열고**, 1)번을 다른 폴더 이름으로 반복.
창마다 다른 문제가 동시에 돌아감.

---

## 5) 모델 지정 (상황별)

```powershell
# Codex 로그인이 안 됐을 때 — Claude 2개만 사용
uv run ctf-solve --challenge challenges\for-01 --no-submit -v `
  --models claude-sdk/claude-opus-4-6/medium `
  --models claude-sdk/claude-opus-4-6/max
```
(아무것도 안 붙이면 기본 5개 모델 = Claude 2 + Codex 3 자동 사용.)

---

## 플래그 옵션 뜻

| 옵션 | 뜻 |
|------|-----|
| `--challenge <폴더>` | 그 폴더의 문제 하나를 풂 |
| `--no-submit` | 플랫폼에 제출 안 함(화면 출력만). **DAKER에선 항상 사용** |
| `-v` | 진행 과정을 자세히 로그로 표시 |
| `--models ...` | 쓸 모델 지정(반복 가능). 생략하면 기본 5개 |

---

## 자주 막히는 지점

- **`docker ps` 에러**: Docker Desktop이 안 켜짐 → 실행 후 다시.
- **`uv` 명령 없음**: 새 터미널을 열거나, uv 설치 확인.
- **특정 모델만 실패**: 그 모델이 구독에서 안 열리는 것 → `--models`로 되는 것만 지정.
- **인스턴스 접속 안 됨**: 대회 WiFi 연결 확인. `connection_info` 주소 오타 확인.
- **첨부파일 분석이 안 됨**: 파일을 `distfiles\` 안에 넣었는지 확인.

막히면 에러 메시지를 Claude Code(또는 데스크톱 대화)에 그대로 붙여넣고 물어볼 것.
