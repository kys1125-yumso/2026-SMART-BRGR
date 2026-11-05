# CTF Agent + CTF Skills 통합 (구독 전용 구성)

`verialabs/ctf-agent`(오케스트레이션 뼈대)에 `ljagiello/ctf-skills`(카테고리별 공격
기법 지식)를 **동적 로딩** 방식으로 결합한 사본입니다. 원본 다운로드본은 건드리지 않았습니다.

## 무엇이 바뀌었나

1. **`skills/`** — ctf-skills의 카테고리 지식 디렉터리(ctf-crypto, ctf-pwn, ctf-web,
   ctf-reverse, ctf-forensics, ctf-misc, ctf-osint, ctf-malware, ctf-ai-ml 등)를 복사.
2. **`sandbox/Dockerfile.sandbox`** — `COPY skills /skills` 한 줄 추가. 샌드박스
   컨테이너 안 `/skills`에 지식 베이스가 읽기 전용으로 들어갑니다.
3. **`backend/prompts.py`** — `CATEGORY_SKILL_MAP`과 `_skills_section()` 추가.
   `build_prompt()`가 문제 카테고리에 맞는 `/skills/<dir>/` 경로를 시스템 프롬프트에
   안내합니다. 지식 전체를 프롬프트에 넣지 않고, 솔버가 막혔을 때 `cat`으로 필요한
   파일만 읽게 하는 지연 로딩 구조입니다(토큰 절약).
4. **`backend/agents/claude_solver.py`, `codex_solver.py`** — 샌드박스 프리앰블을
   수정해 `/skills` 읽기 전용 접근을 허용(기존엔 `/challenge/` 밖을 모두 금지했음).

동작 흐름: 코디네이터가 문제를 분류 → 스웜이 솔버를 띄움 → 솔버가 막히면
`cat /skills/ctf-crypto/SKILL.md` 같은 bash 명령으로 기법을 조회해 공격을 이어감.

## 구독 전용으로 돌리기 (Claude + Codex)

API 키 없이 두 CLI의 구독 로그인만으로 기본 5개 모델 스웜을 그대로 쓸 수 있습니다.

```bash
# 1) 두 CLI 로그인 (구독 인증)
claude            # 로그인 상태 확인
codex             # 로그인 상태 확인

# 2) 의존성 설치 (Python 3.14+, uv 필요)
uv sync

# 3) 샌드박스 이미지 빌드 (프로젝트 루트에서 실행 — build context가 루트여야 /skills 복사됨)
docker build -f sandbox/Dockerfile.sandbox -t ctf-sandbox .

# 4) .env 준비 — API 키는 비워도 됨, CTFd 정보만 채움
cp .env.example .env
#   CTFD_URL=... / CTFD_TOKEN=... 입력, ANTHROPIC/OPENAI/GEMINI 키는 공란 유지

# 5) 실행
uv run ctf-solve \
  --ctfd-url https://ctf.example.com \
  --ctfd-token ctfd_... \
  --max-challenges 10 -v
```

기본 모델 목록(`backend/models.py`의 `DEFAULT_MODELS`)은 그대로 둡니다.
`claude-sdk/*`는 `claude` 구독, `codex/*`는 `codex` 구독으로 돕니다.

## 주의할 점

- **쿼터 폴백**: `backend/agents/swarm.py`의 `QUOTA_FALLBACK`은 구독 쿼터 소진 시
  Bedrock/Azure(API)로 넘어갑니다. API 자격이 없으면 그 모델만 실패하고 나머지는 계속
  진행합니다. 폴백을 아예 끄려면 `QUOTA_FALLBACK = {}`로 비우세요.
- **모델 ID**: `DEFAULT_MODELS`의 `claude-opus-4-6`, `gpt-5.4` 계열 ID가 각 구독에서
  실제 접근 가능한 모델명과 일치해야 합니다. 안 맞으면 해당 솔버만 거부됩니다.
- **Windows**: Docker Desktop + WSL2 백엔드가 필요합니다. 솔버 작업은 전부 Linux
  컨테이너 안에서 실행됩니다.
- **CTFd 전제**: 이 에이전트는 CTFd 기반 대회에 토큰으로 붙어 문제를 자동 수집합니다.
  단일 파일 문제만 풀려면 `--challenge <dir>` 단일 모드를 쓰세요.

## 지식 베이스 갱신

ctf-skills 원본이 업데이트되면 `skills/`를 다시 복사하고 이미지를 재빌드하면 됩니다.

```bash
# 예: 최신 ctf-skills를 skills/ 로 다시 복사 후
docker build -f sandbox/Dockerfile.sandbox -t ctf-sandbox .
```
