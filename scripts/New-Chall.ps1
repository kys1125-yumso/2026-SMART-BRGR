<#
  New-Chall : 대회 당일 CTF 문제 폴더를 한 줄로 생성하는 helper.

  쓰기 전 한 번 (터미널마다):
      . .\scripts\New-Chall.ps1

  사용 예:
      New-Chall web                         # 분야만. 메모장 떠서 지문 붙여넣기 → 저장·닫기. 최근 다운로드 자동 흡수
      New-Chall web "로그인 우회해서 admin 되기"    # 짧은 지문은 한 줄로
      New-Chall crypto "RSA n,e,c" .\a.txt      # 파일 직접 지정
      New-Chall web "설명" -Conn "http://10.1.2.3:8080"   # 인스턴스형(접속주소)
      New-Chall web "설명" -Run                 # 생성 후 바로 풀이 실행

  입력은 딱 두 개 (분야 + 설명)면 충분. 나머지는 자동.
#>

function New-Chall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Category,                       # web | pwn | forensics | reverse | crypto | misc

        [Parameter(Position = 1)]
        [string]$Description,                     # 짧으면 여기, 길면 비워두면 메모장이 열림

        [Parameter(Position = 2)]
        [string]$File,                            # 파일 경로 직접 지정(생략 시 최근 다운로드 자동)

        [string]$Name,                            # 폴더 이름 직접 지정(생략 시 <분야>-NN 자동)
        [int]$Value = 500,                        # 배점(표시용)
        [string]$Conn,                            # 인스턴스 접속주소. 주면 인스턴스형으로 처리
        [switch]$NoFile,                          # 다운로드 자동 흡수 끄기
        [switch]$Run                              # 생성 후 바로 ctf-solve 실행
    )

    # 프로젝트 루트 (= scripts 폴더의 부모). 직접 붙여넣어 실행했으면 현재 폴더.
    $root = if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { (Get-Location).Path }
    $chRoot = Join-Path $root 'challenges'
    if (-not (Test-Path $chRoot)) { New-Item -ItemType Directory -Path $chRoot | Out-Null }

    # 폴더 이름 자동: <category>-01, -02 ...
    if (-not $Name) {
        $n = 1
        while (Test-Path (Join-Path $chRoot ("{0}-{1:D2}" -f $Category, $n))) { $n++ }
        $Name = "{0}-{1:D2}" -f $Category, $n
    }
    $dir = Join-Path $chRoot $Name
    if (Test-Path $dir) {
        Write-Host "이미 있는 폴더입니다: $Name" -ForegroundColor Yellow
        return
    }
    New-Item -ItemType Directory -Path $dir | Out-Null
    $dist = Join-Path $dir 'distfiles'
    New-Item -ItemType Directory -Path $dist | Out-Null

    $isInstance = [bool]$Conn

    # --- 설명 수집 ---
    if (-not $Description) {
        # 긴 지문: 메모장에 붙여넣고 저장 후 닫기
        $tmp = Join-Path $dir 'description.txt'
        $hint = "# 이 줄 아래에 출제자 지문을 그대로 붙여넣고 저장(Ctrl+S) 후 메모장을 닫으세요."
        Set-Content -Path $tmp -Value $hint -Encoding UTF8
        Write-Host "메모장이 열립니다. 지문 붙여넣고 저장 후 창을 닫으세요..." -ForegroundColor Cyan
        Start-Process notepad.exe -ArgumentList $tmp -Wait
        $raw = Get-Content -Path $tmp -Raw -Encoding UTF8
        if ($null -eq $raw) { $raw = "" }
        $Description = (($raw -split "`r?`n") | Where-Object { $_ -notmatch '^#\s*이 줄 아래에' }) -join "`n"
        $Description = $Description.Trim()
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
    if (-not $Description) { $Description = "(지문 없음)" }

    # YAML 블록 스칼라용 들여쓰기 (각 줄 앞 2칸)
    $descBlock = (($Description -split "`r?`n") | ForEach-Object { "  $_" }) -join "`n"

    # --- 파일 배치 ---
    # 파일을 직접 지정하면 인스턴스형이어도 복사(pwn 인스턴스 = 바이너리 + 접속주소).
    # 자동 흡수는 파일형에서만(인스턴스 웹은 불필요한 다운로드를 끌어오지 않도록).
    if ($File) {
        if (Test-Path $File) {
            Copy-Item -Path $File -Destination $dist
            Write-Host ("파일 복사: " + (Split-Path $File -Leaf)) -ForegroundColor Green
        }
        else {
            Write-Host "파일을 찾을 수 없음: $File" -ForegroundColor Red
        }
    }
    elseif (-not $isInstance -and -not $NoFile) {
        $dl = Join-Path $HOME 'Downloads'
        $latest = Get-ChildItem -Path $dl -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latest) {
            Copy-Item -Path $latest.FullName -Destination $dist
            Write-Host ("최근 다운로드 흡수: " + $latest.Name) -ForegroundColor Green
        }
        else {
            Write-Host "Downloads 폴더에 파일 없음 — distfiles 비어 있음" -ForegroundColor Yellow
        }
    }

    # --- metadata.yml 작성 ---
    $connLine = if ($isInstance) { "connection_info: `"$Conn`"" } else { 'connection_info: ""' }
    $meta = @"
name: "$Name"
category: "$Category"
value: $Value
description: |
$descBlock
$connLine
"@
    Set-Content -Path (Join-Path $dir 'metadata.yml') -Value $meta -Encoding UTF8

    Write-Host ""
    Write-Host "생성 완료: challenges\$Name  (category=$Category)" -ForegroundColor Green
    if ($isInstance) { Write-Host "  인스턴스 접속: $Conn" -ForegroundColor Gray }
    Write-Host "실행:  uv run ctf-solve --challenge challenges\$Name --no-submit -v" -ForegroundColor White

    if ($Run) {
        Push-Location $root
        try { uv run ctf-solve --challenge "challenges/$Name" --no-submit -v }
        finally { Pop-Location }
    }
}
