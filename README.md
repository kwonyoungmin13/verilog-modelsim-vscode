# Verilog Practice with VS Code and ModelSim

Windows에서 VS Code와 ModelSim으로 Verilog를 작성하고 시뮬레이션하는 학습 환경입니다. **Ctrl+Shift+B**로 파일 저장, 소스 컴파일, 테스트벤치 실행, 파형 표시를 한 번에 진행합니다.

저장소에는 VS Code 설정, 실행 스크립트, 예제와 학습 소스가 들어 있습니다. ModelSim 실행 파일과 라이선스는 포함하지 않습니다.

## 필요한 프로그램

- Windows 및 Windows PowerShell 5.1
- [Visual Studio Code](https://code.visualstudio.com/download)
- ModelSim - Intel FPGA Starter Edition 2020.1

ModelSim 2020.1에서 확인했으며 다른 버전은 검증하지 않았습니다. VS Code와 ModelSim은 각 PC에 별도로 설치해야 합니다.

## 처음 실행하기

1. GitHub의 **Code → Download ZIP**으로 내려받아 압축을 풀거나 저장소를 clone합니다.
2. VS Code에서 **File → Open Folder**로 `README.md`가 있는 프로젝트 루트 폴더를 엽니다.
3. **Terminal → Run Task → ModelSim: Setup**을 한 번 실행합니다.
4. `examples/mux4to1/mux4to1.v` 또는 `mux4to1_tb.v`를 엽니다.
5. **Ctrl+Shift+B**를 누르면 ModelSim이 열리고 Wave 창에 파형이 표시됩니다.

Setup 작업 대신 VS Code의 터미널에서 아래 명령을 실행해도 됩니다. 이후 명령도 모두 프로젝트 루트에서 실행합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-modelsim.ps1
```

Setup은 ModelSim 실행 파일과 결과 저장 경로를 찾고, 이 PC의 설정을 `modelsim.local.json`에 저장합니다. VS Code의 `mshr-h.veriloghdl` 확장도 설치합니다. VS Code CLI를 찾지 못하면 **Extensions(Ctrl+Shift+X)**에서 `mshr-h.veriloghdl`을 검색해 직접 설치합니다.

ModelSim을 자동으로 찾지 못하면 `vsim.exe`가 있는 실제 폴더를 지정합니다. 아래 설치 경로는 예시입니다. 같은 폴더에 `vlib.exe`, `vmap.exe`, `vlog.exe`, `vsim.exe`가 있어야 합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-modelsim.ps1 -BinPath "C:\intelFPGA\20.1\modelsim_ase\win32aloem"
```

확장을 설치하지 않으려면 `-SkipExtension`을 추가합니다. 실행 파일을 찾을 수 있는지만 확인하려면 `-CheckOnly`를 사용합니다. `-CheckOnly`는 파일, 설정, 확장을 변경하지 않습니다.

## 개인 설정

`modelsim.json`은 공통 기본값이고, `modelsim.local.json`의 값이 우선 적용됩니다. 개인 설치 경로는 Git에서 제외되는 `modelsim.local.json`에 저장하므로 다른 사람의 설정에 영향을 주지 않습니다.

| 설정 | 의미 |
| --- | --- |
| `binPath` | ModelSim 실행 파일 폴더. 비어 있으면 자동 검색 |
| `buildRoot` | 결과 저장용 영문 경로. 비어 있으면 자동 선택 |
| `runTime` | 한 번에 실행할 시뮬레이션 시간. 기본 `1 us` |
| `top` | 테스트벤치 모듈 이름. 빈 문자열이면 자동 선택 |

`runTime`이나 `top`을 개인별로 변경할 때도 `modelsim.local.json`에 해당 항목을 추가하면 됩니다. Setup을 다시 실행해도 기존 옵션은 유지되고 `binPath`, `buildRoot`만 갱신됩니다.

`%TEMP%`에 한글이 있으면 공용 문서 폴더의 영문 경로를 사용합니다. 자동 선택한 경로에 쓸 수 없다면 쓰기 권한이 있는 영문 경로를 직접 지정합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup-modelsim.ps1 -BuildRoot "C:\Users\Public\Documents\Verilog-ModelSim"
```

## 폴더 구조

```text
.
├── .vscode/                  # 빌드 작업, 편집 설정, 추천 확장
├── scripts/
│   ├── setup-modelsim.ps1    # PC별 초기 설정
│   ├── modelsim-common.ps1   # 설정 읽기와 경로 검색
│   └── modelsim.ps1          # 컴파일 및 시뮬레이션
├── examples/mux4to1/          # 처음 실행할 4:1 mux 예제
├── studyfile/                 # 회로별 학습 소스와 테스트벤치
├── modelsim.json              # 공통 기본값
├── modelsim.local.json        # Setup이 생성하는 개인 설정, Git 제외
└── README.md
```

## VS Code 작업

**Terminal → Run Task**에서 작업을 선택할 수 있습니다.

| 작업 | 동작 |
| --- | --- |
| ModelSim: Setup | ModelSim 경로와 개인 설정, 편집 확장 준비 |
| ModelSim: Build and Show Waveform | 기본 빌드. 컴파일 후 GUI에서 시뮬레이션과 파형 표시 |
| ModelSim: Check Simulation (Terminal) | GUI 없이 실행하고 로그와 WLF 파형 저장 |
| ModelSim: Compile Only | 시뮬레이션 없이 소스 컴파일 |

빌드 전에 편집 중인 파일을 저장합니다. 컴파일에 실패하면 GUI를 열지 않고 오류를 표시하며, **Problems**에서 파일과 줄로 이동할 수 있습니다. 프로젝트 폴더 전체를 열어야 이 작업들이 적용됩니다.

## 터미널에서 시뮬레이션하기

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\modelsim.ps1 -SourcePath .\examples\mux4to1\mux4to1_tb.v -Action Batch
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\modelsim.ps1 -SourcePath .\studyfile\week1\mux\mux_tb.v -Action Batch
```

첫 번째 예제는 입력을 바꾸며 파형을 관찰하는 테스트벤치입니다. 두 번째 예제는 mux의 64가지 입력·선택 조합을 검사하고, 모두 맞으면 `PASS`를 출력합니다.

학습용 테스트벤치는 입력 자극과 `$stop`만 있는 경우도 있습니다. `$stop`을 정상 중단으로 처리해 결과를 저장한 뒤 Batch 작업을 마칩니다. `SIMULATION OK`는 실행이 완료되었다는 뜻이며, 회로의 정답 여부는 파형이나 테스트벤치의 검사 결과로 확인합니다.

## 내 실습 추가하기

예제 폴더를 `studyfile` 아래로 복사한 뒤 회로와 테스트벤치를 수정해 시작할 수 있습니다.

```powershell
Copy-Item -LiteralPath .\examples\mux4to1 -Destination .\studyfile\my-mux -Recurse
```

- 회로마다 폴더를 나누고 `회로이름.v`, `회로이름_tb.v`를 같은 폴더에 둡니다.
- 테스트벤치의 **모듈 이름**을 `mux4to1_tb` 또는 `tb_mux4to1`처럼 지정합니다. 파일 이름만 변경해서는 자동 선택되지 않습니다.
- 기본적으로 현재 파일과 같은 폴더의 `.v`, `.sv`를 모두 컴파일합니다. `include` 헤더도 해당 폴더를 기준으로 찾습니다.
- 하위 폴더 소스나 SystemVerilog package의 컴파일 순서를 지정하려면 회로 폴더에 `files.f`를 만듭니다. 회로 폴더 기준 상대 경로를 한 줄에 하나씩 순서대로 적습니다. 빈 줄과 `#`/`//` 주석을 지원하며 vlog 옵션은 적지 않습니다. 모든 소스는 프로젝트 안에 둡니다.
- 테스트벤치가 여러 개라면 원하는 `_tb.v`를 열어 빌드하거나 개인 설정의 `top`에 실행할 모듈 이름을 지정합니다.

## 결과 파일과 파형

기본 파형은 테스트벤치의 최상위 신호만 이진수(binary)로 표시합니다.

결과는 `.modelsim/회로폴더/실행시각/`에서 확인합니다. `waves.wlf`는 파형, `simulation.log`는 실행 로그이며 GUI 실행 시 `wave.do`에 파형 배치도 저장합니다. `.modelsim`은 VS Code 탐색기와 검색에서 숨겨져 있으므로 터미널에 출력된 경로나 Windows 탐색기로 확인합니다.

실제 결과는 `buildRoot/runs/` 아래에 생성하며, `.modelsim` 아래의 실행별 폴더는 해당 위치를 가리키는 Windows junction입니다. 원본 소스도 영문 경로의 junction으로 읽어 한글 작업 폴더에서 발생하는 ModelSim 경로 문제를 피합니다. 실행마다 새 폴더와 새 GUI 창을 사용합니다.

GUI의 WLF 기록은 ModelSim을 정상 종료할 때 완료됩니다. 창이 열린 동안에도 Wave에서 파형을 볼 수 있습니다. 실행 직후 파일을 복사하려면 터미널 시뮬레이션을 사용합니다. GUI에서 `$stop` 또는 `$finish`를 만나면 해당 시점에 멈추고 창은 유지됩니다. Transcript의 `run 1 us`로 추가 실행할 수 있습니다.

기본 저장 위치는 임시 폴더이므로 정리되면 이전 결과가 사라질 수 있습니다. 필요한 WLF와 로그는 별도로 보관합니다. 개인 설정과 시뮬레이션 산출물은 `.gitignore`로 Git 추적에서 제외합니다.
