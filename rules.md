# 📜 SYSTEM RULES (Immutable)

You must adhere to these rules for every action taken during the implementation of `task.md`.

1.  **Cross-Feature Impact Scan**: Before applying any code change, scan the entire project to ensure there is no critical influence on other features. If a conflict is detected, **PAUSE** implementation immediately. Provide a concise explanation to the user and await their decision. If the user's direction appears technically risky or incorrect, provide scenarios and examples to verify they understand the consequences before proceeding.
2.  **Loop Trap Prevention**: Remain vigilant against repetitive cycles (errors causing the same fix). If a solution fails twice, stop, re-evaluate the architecture, and propose a new path.
3.  **Post-Implementation Analysis**: After finishing the implementation, run `flutter analyze`. Explain any errors or warnings in a friendly, understandable way and ask for explicit permission to solve them.
4.  **Zero-Defect Mandate**: Do not consider the task complete until `flutter analyze` returns **0 errors and 0 warnings**.
