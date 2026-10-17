# Verilog Practice with VS Code and ModelSim

VS Code에서 Verilog를 작성하고 ModelSim으로 시뮬레이션하는 실습 프로젝트입니다. **Ctrl+Shift+B**를 누르면 파일 저장, 소스 컴파일, 테스트벤치 실행, 파형 표시까지 이어집니다.

## 주요 기능

- Verilog/SystemVerilog 파일의 빌드 및 테스트벤치 자동 선택
- ModelSim GUI 실행과 Wave 창 자동 표시
- 터미널 시뮬레이션 및 컴파일 전용 작업
- VS Code Problems에서 컴파일 오류 위치 확인
- 한글 작업 폴더를 위한 영문 경로 연결 및 실행별 결과 분리
- counter와 mux 예제 및 결과를 검사하는 테스트벤치

## 실행 환경

- Windows 및 Windows PowerShell 5.1
- Visual Studio Code
- ModelSim - Intel FPGA Starter Edition 2020.1

다른 ModelSim 버전은 검증하지 않았습니다. VS Code와 ModelSim은 별도로 설치해야 합니다. 문법 강조용 `mshr-h.veriloghdl` 확장은 `.vscode/extensions.json`의 추천 목록에 포함되어 있습니다.

## 시작하기

1. GitHub에서 **Code → Download ZIP**으로 내려받아 압축을 풀거나, 저장소를 `git clone`합니다.
2. VS Code에서 **File → Open Folder**로 이 프로젝트의 루트 폴더 전체를 엽니다.
3. `modelsim.json`의 `binPath`를 본인 PC의 ModelSim 실행 파일 폴더로 수정합니다.
4. `week1/counter/counter.v` 또는 `counter_tb.v`를 열고 **Ctrl+Shift+B**를 누릅니다.
5. ModelSim의 **Wave** 창에서 `clk`, `reset`, `enable`, `count` 파형을 확인합니다.

`week1/mux/mux.v`에서도 같은 방식으로 mux 예제를 실행할 수 있습니다. 파일만 단독으로 열면 프로젝트의 빌드 작업이 적용되지 않습니다.

```json
{
  "binPath": "C:/intelFPGA/20.1/modelsim_ase/win32aloem",
  "runTime": "1 us",
  "top": ""
}
```

`binPath`에는 `vlib.exe`, `vmap.exe`, `vlog.exe`, `vsim.exe`가 있는 폴더를 지정합니다. 설정 경로에서 찾지 못하면 PATH의 `vsim.exe` 위치를 확인합니다. `runTime`은 실행 시간이며, `top`이 빈 문자열이면 테스트벤치 모듈을 자동 선택합니다.

## 폴더 구조

```text
.
├── .vscode/              # VS Code 작업, 편집 설정, 추천 확장
├── scripts/modelsim.ps1  # 컴파일 및 시뮬레이션 실행 스크립트
├── week1/
│   ├── counter/          # 4비트 카운터와 테스트벤치
│   └── mux/              # 4:1 멀티플렉서와 테스트벤치
├── modelsim.json         # ModelSim 경로, 실행 시간, top 설정
├── .gitignore
└── README.md
```

## VS Code 작업

**Terminal → Run Task**에서 작업을 선택할 수 있습니다.

| 작업 | 동작 |
| --- | --- |
| ModelSim: Build and Show Waveform | 기본 빌드. 컴파일 후 GUI에서 시뮬레이션과 파형 표시 |
| ModelSim: Check Simulation (Terminal) | GUI 없이 시뮬레이션하고 로그와 WLF 저장 |
| ModelSim: Compile Only | 시뮬레이션 없이 소스 컴파일 |

컴파일에 실패하면 GUI를 실행하지 않고 터미널에 오류를 표시합니다. 컴파일 오류는 **Problems**에서도 해당 파일과 줄로 이동할 수 있습니다. GUI에서 `$finish`를 만나면 실행을 멈추고 창을 유지합니다. Transcript에 `run 1 us`를 입력하면 추가로 실행할 수 있습니다.

## 새 회로 추가하기

- 회로마다 폴더를 만들고 `회로이름.v`, `회로이름_tb.v`를 같은 폴더에 둡니다.
- 테스트벤치의 **모듈 이름**을 `counter_tb` 또는 `tb_counter`처럼 지정합니다. 파일 이름만 변경해서는 자동 선택되지 않습니다.
- 기본적으로 현재 파일과 같은 폴더의 `.v`와 `.sv`를 모두 컴파일합니다. 다른 회로의 소스는 별도 폴더로 구분합니다.
- 하위 폴더의 소스나 SystemVerilog package 순서를 지정하려면 회로 폴더에 `files.f`를 추가합니다. 회로 폴더 기준 상대 경로를 한 줄에 하나씩, 컴파일 순서대로 적습니다. 빈 줄과 `#`/`//` 주석을 지원하며 vlog 옵션은 적지 않습니다.
- `include` 헤더는 현재 회로 폴더를 기준으로 찾습니다.

테스트벤치가 여러 개라면 원하는 `_tb.v` 파일을 선택해 빌드하거나, `modelsim.json`의 `top`에 실행할 모듈 이름을 지정합니다.

## 터미널에서 예제 확인하기

프로젝트 루트에서 다음 PowerShell 명령을 실행합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\modelsim.ps1 -SourcePath .\week1\counter\counter_tb.v -Action Batch
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\modelsim.ps1 -SourcePath .\week1\mux\mux_tb.v -Action Batch
```

counter 테스트벤치는 리셋, enable, 값 유지, 오버플로를 확인합니다. mux 테스트벤치는 입력과 선택 신호의 64가지 조합을 확인합니다. 각 테스트벤치는 통과하면 `PASS`를 출력하고, 값이 다르면 `$fatal`로 실패를 알립니다.

## 시뮬레이션 결과

결과는 `.modelsim/회로폴더/실행시각/`에서 확인할 수 있습니다. `waves.wlf`는 파형, `simulation.log`는 로그이며, GUI 실행 시 `wave.do`에 파형 배치를 저장합니다. `.modelsim`은 VS Code 탐색기와 검색에서 숨겨져 있으므로 터미널에 출력된 경로나 Windows 탐색기로 확인합니다. 실행마다 새 결과 폴더와 새 GUI 창이 열립니다.

GUI 실행의 WLF 기록은 ModelSim을 정상 종료할 때 완료됩니다. 창이 열린 동안에도 Wave에서 파형을 볼 수 있습니다. 실행 직후 파형 파일을 복사하려면 터미널 시뮬레이션 작업으로 생성합니다.

ModelSim 2020.1의 한글 경로 문제를 피하기 위해 실제 결과는 영문 경로인 `%TEMP%/Verillog-ModelSim/runs/` 아래에 생성합니다. `%TEMP%` 자체도 영문 경로여야 합니다. `.modelsim` 아래의 실행별 폴더는 해당 결과 폴더를 가리키는 Windows junction이며, 원본 소스도 영문 경로의 junction을 통해 읽습니다.

임시 폴더를 정리하면 이전 결과도 사라지므로 필요한 WLF와 로그는 별도로 보관합니다. `.modelsim`과 시뮬레이션 산출물은 `.gitignore`로 Git 추적에서 제외합니다.
