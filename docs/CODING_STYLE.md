# Verilog formatting

- Four spaces per indentation level; target line length 100 characters.
- One port per line, with an explicit direction and width on each port.
- Named module connections, one connection per line.
- One statement per line; separate declarations, assignments and processes visibly.
- Nonblocking assignments for stored state; blocking for combinational calculations.
  Existing temporary loop variables are not changed by a formatting pass.
- Preserve meaningful comments and owner/TODO notes.
- Keep supplied vendor drivers outside automated formatting.

The checked-in .verible-format contains formatter settings. Install Verible,
then run from PowerShell:

```powershell
./scripts/format.ps1 -FormatterPath 'C:/path/to/verible-verilog-format.exe'
```

Formatter used for initial cleanup: Verible v0.0-4296-g0f262651.
