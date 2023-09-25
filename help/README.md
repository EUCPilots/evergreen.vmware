# platyPS Help

platyPS help markdown can be found here: [/docs/help](/docs/help).

To generate the external help use `New-ExternalHelp`:

```powershell
Update-MarkdownHelp -Path "./help"
New-ExternalHelp -Path "./help" -OutputPath "./src" -Encoding ([System.Text.Encoding]::UTF8) -Force
```

```powershell
Update-MarkdownHelpModule -Path "./help"
```
