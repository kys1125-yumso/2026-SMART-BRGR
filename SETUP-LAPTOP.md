# 집 노트북 설치 가이드 (대회장 노트북용)

이 순서대로 하면 자동 에이전트가 노트북에서 돕니다. 위에서 아래로 한 번만 하면 됩니다.
**대회 전날까지는 끝내세요.** 특히 마지막 Docker 빌드가 오래 걸립니다.

> 전제: 이 노트북이 대회장에서 **대회 WiFi에 붙여 쓸 바로 그 노트북**입니다.
> 인스턴스 문제는 이 노트북에서 실행해야 접속됩니다.

---

## 0. 프로젝트 폴더를 노트북으로 옮기기

지금 통합된 프로젝트는 데스크톱의 `C:\Users\KEI\Desktop\ctf-agent` 에 있습니다.
이 폴더 전체를 노트북으로 복사하세요. 둘 중 편한 방법:

- **USB/클라우드**: `ctf-agent` 폴더를 통째로 복사 → 노트북의 `C:\Users\<사용자>\Desktop\ctf-agent` 에 붙여넣기.
- 복사 후, 아래 모든 명령은 노트북에서 그 폴더를 기준으로 실행합니다.

`skills/`, `INTEGRATION.md`, `CONTEST-WORKFLOW.md`, `challenges/` 가 폴더 안에 함께 있어야 정상입니다.

---

## 1. WSL2 + Docker Desktop (가장 무거움, 관리자 권한·재부팅 필요)

1. **WSL2 설치** (PowerShell 관리자로 실행):
   ```powershell
   wsl --install
   ```
   재부팅 후 Ubuntu가 한 번 열리며 사용자 계정을 만듭니다.
2. **Docker Desktop 설치**: https://www.docker.com/products/docker-desktop 에서 Windows용 설치.
   설치 중 "Use WSL2 backend" 옵션을 켭니다.
3. 설치 후 Docker Desktop을 실행해 두고, 확인:
   ```powershell
   docker --version
   docker run --rm hello-world
   ```
   `hello-world`가 뜨면 성공입니다.

---

## 2. Python 3.14 + uv

1. **Python 3.14** 설치: https://www.python.org/downloads/ 에서 3.14.x Windows 설치본.
   설치 시 "Add python.exe to PATH" 체크.
   ```powershell
   py -3.14 --version
   ```
2. **uv** 설치 (PowerShell):
   ```powershell
   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
   ```
   새 터미널을 열고:
   ```powershell
   uv --version
   ```

---

## 3. 두 CLI 로그인 (구독 인증)

1. **claude CLI**: 이미 쓰고 있다면 로그인 상태만 확인.
   ```powershell
   claude --version
   ```
2. **codex CLI** 설치 후 로그인 (OpenAI 구독):
   ```powershell
   npm install -g @openai/codex
   codex --version
   codex       # 처음 실행 시 로그인 안내를 따름
   ```
   > codex 로그인이 안 되면, 기본 모델 5개 중 GPT 3개가 빠집니다. 그래도 Claude 2개로 동작은 합니다.

---

## 4. 의존성 설치 + 모델 ID 점검

프로젝트 폴더에서:
```powershell
cd C:\Users\<사용자>\Desktop\ctf-agent
uv sync
```

**모델 ID 확인** — `backend/models.py` 의 `DEFAULT_MODELS` 가 당신 구독에서 실제
접근 가능한 모델명과 맞아야 합니다. 기본값:
```
claude-sdk/claude-opus-4-6/medium
claude-sdk/claude-opus-4-6/max
codex/gpt-5.4
codex/gpt-5.4-mini
codex/gpt-5.3-codex
```
구독에서 이 이름이 안 열리면 그 솔버만 실패합니다. 안 맞으면 `--models` 플래그로
실제 쓸 수 있는 모델만 지정해 돌리면 됩니다. (모르면 이 파일을 Claude에게 보여주고
"내 구독 모델에 맞게 고쳐줘" 하세요.)

---

## 5. 샌드박스 이미지 빌드 (시간 오래 걸림, 대회 전날까지)

```powershell
docker build -f sandbox/Dockerfile.sandbox -t ctf-sandbox .
```
SageMath·CADO-NFS·PyTorch를 받아 컴파일하므로 **30분~1시간+** 걸립니다.
이게 끝나야 `skills/` 지식도 컨테이너 안 `/skills` 에 들어갑니다.
네트워크가 끊기면 중간 실패할 수 있으니 안정된 인터넷에서 하세요.

---

## 6. 스모크 테스트 (빌드 후 1회)

문제 없이 도는지 샘플로 확인:
```powershell
# 파일형 템플릿을 복사해 간단한 테스트 문제를 만들어도 되고,
# 아래처럼 예시 폴더로 바로 돌려봐도 됩니다 (실제 플래그는 없지만 흐름 확인용):
uv run ctf-solve --challenge challenges\_example-file --no-submit -v
```
컨테이너가 뜨고, 솔버가 `/skills` 를 읽고, 과정이 로그로 흐르면 준비 완료입니다.

---

## 대회 당일 사용법 (요약)

문제 1개 = 폴더 1개. 자세한 건 `CONTEST-WORKFLOW.md` 참고.
```powershell
# 1) 템플릿 복사 (파일형)
Copy-Item -Recurse challenges\_example-file challenges\for-01
# 2) challenges\for-01\metadata.yml 채우고, 첨부파일을 distfiles\ 에 복사
# 3) 실행
uv run ctf-solve --challenge challenges\for-01 --no-submit -v
# 4) "FLAG FOUND: DAKER{...}" 를 DAKER 웹 폼에 수동 제출
```

- **파일형 20문제**: 위 방식으로 자동 처리 (주력).
- **인스턴스 5문제**: Claude Code 대화형으로. 인스턴스 띄워 주소+지문을 Claude에게 주면 됨.
- 동시에 여러 문제를 돌리려면 터미널을 여러 개 열어 각각 다른 `--challenge` 폴더로 실행.

---

## 막히면

이 가이드의 어느 단계든 막히면, 그 단계의 에러 메시지를 Claude Code(또는 데스크톱의
이 대화)에 그대로 붙여넣고 물어보세요. 단계별로 같이 해결하면 됩니다.
