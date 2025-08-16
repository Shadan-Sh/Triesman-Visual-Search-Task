# Visual Search (Psychtoolbox / MATLAB)

A Treisman-style **visual search** task implemented in **MATLAB + Psychtoolbox 3.0.19.15**. The participant searches for a **red triangle** among distractors. The script prompts for a **Subject ID**, runs a **practice block (no saving)**, then runs the **main experiment** and saves results.

## Features

* Two search types: **Feature** and **Conjunction**
* Array sizes: **4, 8, 16, 32**
* Keys: **Y** = target present, **N** = target absent, **ESC** = safe quit
* **Practice block** with feedback (Correct/Incorrect) — **not saved**
* **Main block** without feedback — results saved to CSV with Subject ID and timestamp

## Requirements

* MATLAB (64‑bit)
* Psychtoolbox **3.0.19.15** or compatible (Windows/macOS/Linux)
* (Windows) Microsoft **Visual C++ 2015–2019 x64** runtime

> After downloading PTB, in MATLAB run `SetupPsychtoolbox` from the PTB root to set the path correctly.

## Quick PTB check

```matlab
% In MATLAB:
SetupPsychtoolbox        % set up PTB path
PsychtoolboxVersion      % verify PTB is found
```

## How to run

1. Open MATLAB and navigate to your project folder (e.g., `src/`).
2. Open and run:

   ```matlab
   VisualSearchTask
   ```
3. Enter **Subject ID** (e.g., `ke1`) when prompted.
4. Read on‑screen instructions → **SPACE** → view target example → **SPACE** → practice → main experiment.

## Controls

* **Y**: red triangle **present**
* **N**: red triangle **absent**
* **ESC**: quit the task at any time
* Feedback shows only during **practice**.

## Output

* CSV file named like:

  ```
  visual_search_results_<subID>_<yyyymmdd_HHMMSS>.csv
  ```
* Columns: `trial, subID, present, searchType, arraySize, response, RT, correct`

## Suggested folder layout

```
visual-search-ptb/
├─ src/
│  └─ VisualSearchTask_with_ID_and_Practice.m
├─ results/            # outputs (optional: add to .gitignore)
├─ README.md
└─ .gitignore
```

## Quick customization

* Repetitions per condition: `nRepsPerCondition`
* Keys: handled in `PresentSearchDisplay` (currently Y/N/ESC)
* Stimulus size: `stimSize`
* Minimum spacing: `minDistance`

## Troubleshooting (Windows)

* **PsychHID / KbCheck errors** → run `SetupPsychtoolbox`; ensure `which PsychHID -all` shows the **.mexw64** before the `.m` shim.
* **Flip/timing warnings** → before `OpenWindow` you can try:

  ```matlab
  Screen('Preference','VBLTimestampingMode', 1);  % or 0 if needed
  % For development only:
  Screen('Preference','SkipSyncTests', 1);
  ```
* **DrawText plugin fails** → (re)install **VC++ 2015–2019 x64** runtime.

## Add to GitHub

* **GitHub Desktop** (recommended):

  * If you cloned the repo: copy files into the cloned folder → **Changes** tab → message → **Commit to main** → **Push origin**.
  * If starting from a local folder: **File → Add local repository…** → create repo → **Repository Settings → Remotes** → add your GitHub repo URL as `origin` → **Push**.
* **Web**: In your repo → **Add file → Upload files** → drag & drop → commit.

## License

Add a `LICENSE` file if needed (e.g., MIT). This project is provided for research/educational use.
