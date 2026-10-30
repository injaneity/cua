param([string]$Layout, [string]$Out)
Add-Type -AssemblyName System.Windows.Forms
Add-Type 'using System;using System.Runtime.InteropServices;public static class KL{[DllImport("user32.dll")]public static extern IntPtr LoadKeyboardLayout(string id,uint f);[DllImport("user32.dll")]public static extern IntPtr ActivateKeyboardLayout(IntPtr h,uint f);[DllImport("user32.dll")]public static extern IntPtr GetKeyboardLayout(uint t);}'
$f = New-Object Windows.Forms.Form; $f.Text = 'TARGET'
$tb = New-Object Windows.Forms.TextBox; $tb.Dock = 'Fill'; $tb.Multiline = $true; $f.Controls.Add($tb)
$f.add_Shown({
  [KL]::ActivateKeyboardLayout([KL]::LoadKeyboardLayout($Layout, 0), 0x100) | Out-Null
  $tb.Focus() | Out-Null
  Set-Content -LiteralPath "$Out.layout" -Value ('{0:X8}' -f [KL]::GetKeyboardLayout(0).ToInt64())
})
$t = New-Object Windows.Forms.Timer; $t.Interval = 200
$t.add_Tick({ [IO.File]::WriteAllText($Out, $tb.Text, [Text.Encoding]::UTF8) })
$t.Start()
[Windows.Forms.Application]::Run($f)
