# 2026 호남지역 정보보호 해커톤 — 에이전트 운용 가이드

대회 안내자료(DACON/DAKER 플랫폼)를 반영한 실제 사용법입니다.
핵심: **이 대회는 CTFd가 아니라 자체 DAKER 플랫폼**이고, **제출은 웹 폼으로 수동**이며,
**인스턴스 문제는 대회장 WiFi(지정 IP)에서만** 접속됩니다. 따라서 ctf-agent의
자동 수집·자동 제출(코디네이터/poller/ctfd)은 쓰지 않고, **문제 1개씩 수동 투입** 방식만 씁니다.

## 규칙 확인 (안내자료 기준)

- **AI 도구 사용 허용** — 이 에이전트 사용은 규칙 위반이 아닙니다.
- **외부 조력자 금지 / 타 팀과 풀이·FLAG 공유 금지** — 팀 내부에서만 사용하세요.
- **반복적 무작위 정답 제출 금지** — 그래서 에이전트는 플랫폼에 직접 제출하지 않습니다
  (`--no-submit`). 플래그는 사람이 확인 후 DAKER에 1회 입력합니다.
- **FLAG 형식 `DAKER{...}`** — 대소문자·중괄호·공백 그대로 제출.

## 대회 당일 핵심: 문제 1개 = 폴더 1개

파일형(20문항)·인스턴스형(5문항) 모두 아래 한 가지 흐름입니다.

```bash
# 1) 문제 폴더 준비 (템플릿 복사)
cp -r challenges/_example-file challenges/web-01     # 파일형
#   또는
cp -r challenges/_example-instance challenges/web-01 # 인스턴스형

# 2) metadata.yml 채우기 (category, description, 인스턴스면 connection_info=접속주소)
#    파일형이면 받은 첨부파일을 challenges/web-01/distfiles/ 에 복사

# 3) 에이전트 투입 (플랫폼 접속 없음, 샌드박스에서 자동 풀이)
uv run ctf-solve --challenge challenges/web-01 --no-submit -v

# 4) 화면에 "FLAG FOUND: DAKER{...}" 가 뜨면, 그 값을 DAKER 웹 폼에 직접 제출
```

`--no-submit`이면 에이전트는 플랫폼에 접속하지 않고 플래그만 화면에 출력합니다.
검증은 당신이 DAKER에 제출해서 확인합니다.

## 대회 전 반드시 해둘 것 (11/6 전에)

1. **샌드박스 이미지 미리 빌드.** SageMath·CADO-NFS·PyTorch 포함이라 빌드가 수십 분
   이상 걸립니다. 현장에서 빌드하면 늦습니다.
   ```bash
   docker build -f sandbox/Dockerfile.sandbox -t ctf-sandbox .
   ```
2. **두 CLI 로그인 확인**: `claude`, `codex` (구독 인증). API 키 불필요.
3. **`uv sync`** 로 의존성 설치(Python 3.14+).
4. **스모크 테스트**: 아무 파일형 샘플로 `--challenge ... --no-submit` 1회 돌려
   컨테이너가 뜨고 플래그 흐름이 되는지 확인.

안내자료가 요구하는 로컬 환경(Python 3.10+, Linux/WSL2 x86-64, Wireshark/tshark)도
노트북에 준비하세요. 에이전트가 못 푸는 문제는 팀원이 직접 풀어야 합니다.

## 네트워크 주의 (인스턴스형)

- 인스턴스 접속 주소는 보통 사설 IP(예: `10.x.x.x`, `192.168.x.x`)입니다.
  대회장 WiFi에 붙은 **그 노트북에서 에이전트를 실행**해야 컨테이너가 인스턴스에 닿습니다.
- **claude 솔버는 bash `curl`로 접속**하므로 사설 IP도 그대로 됩니다(문제 없음).
- 단, codex/pydantic 솔버의 `web_fetch` 내장 도구는 사설 IP를 보안상 차단합니다
  (`backend/tools/core.py`의 `_is_internal_url`). 웹 인스턴스에서 이 도구가 막히면,
  해당 솔버는 bash curl로 우회하거나, 원하면 이 차단을 풀어 드립니다(대회 한정).
- `metadata.yml`의 `connection_info`에 `localhost`/`127.0.0.1`을 쓰면 자동으로
  `host.docker.internal`로 바뀝니다. venue IP는 그대로 두세요.

## 공개 일정 (11/6, 참고)

| 시각 | 분야 | 매핑되는 /skills |
|------|------|------------------|
| 14:00 | 웹 해킹 | ctf-web |
| 15:00 | 시스템 해킹(pwn) | ctf-pwn |
| 16:00 | 포렌식 | ctf-forensics |
| 17:00 | 리버싱 | ctf-reverse |
| 19:00 | 암호학 | ctf-crypto |

정답 제출 마감 22:00. 먼저 공개된 문제는 계속 풀 수 있습니다(누적 공개).
동적 배점이라 **빨리 풀수록 점수가 높습니다** — 쉬운 문제를 에이전트로 빠르게 처리하고,
팀원은 어려운 문제에 집중하는 분업이 유리합니다.

## 현실적인 권장 구성

문제가 25개뿐이고 제출이 수동이라, **두 갈래 병행**을 권합니다.

1. **빠른 자동 풀이**: 파일형 EASY/MEDIUM을 폴더로 만들어 `--challenge --no-submit`로
   에이전트에 던져 두고, 나오는 플래그를 수동 제출. 여러 문제를 동시에 돌려도 됩니다
   (`--challenge`를 문제별 터미널에서 각각 실행).
2. **대화형 풀이**: 까다로운 문제는 Claude Code를 venue 노트북에서 직접 띄우고
   `/skills` 지식을 참고해 사람이 주도. 에이전트가 막힌 지점만 거들게 하는 방식.

둘 다 같은 구독으로 돌아가고, 지식 베이스(`skills/`)를 공유합니다.
