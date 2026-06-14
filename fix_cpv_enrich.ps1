
$path = "C:\Users\jochu\Downloads\TED_Ausschreibungs_Monitoring\TED_Ausschreibungs_Monitoring\Main.xaml"
$bak  = $path + ".bak_cpv_enrich"

if (-not (Test-Path $bak)) {
    Copy-Item $path $bak
    "Backup erstellt."
} else {
    "Backup existiert bereits."
}

$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# ─── CHANGE 1: ExtractedData -> dt_HitsPage ─────────────────────────────────
$before1 = $content.Length
$content = $content.Replace('ExtractedData="[dt_Hits]"', 'ExtractedData="[dt_HitsPage]"')
"Change1 (ExtractedData redirect): " + $(if ($content.Length -ne $before1 -or $content.Contains("dt_HitsPage")) {"OK"} else {"UNCHANGED - checking..."})
"dt_HitsPage in content now: " + $content.Contains('ExtractedData="[dt_HitsPage]"')

# ─── CHANGE 2: Add dt_HitsPage Variable to Sequence_24 ──────────────────────
# Insert <Sequence.Variables> before the ViewState closing inside Sequence_24
# Unique anchor: the ViewState close is immediately followed by "currentCpvCode merken" Assign
# We insert <Sequence.Variables> BETWEEN the ViewState close and the Assign

$anchor2 = 'sap2010:WorkflowViewState.IdRef="Assign_103"'
"Anchor2 (Assign_103) present: " + $content.Contains($anchor2)

# Find the position of Assign_103 and look backwards for the ViewState close
$idx = $content.IndexOf($anchor2)
if ($idx -ge 0) {
    # Find the preceding </sap:WorkflowViewStateService.ViewState>
    $viewstateClose = '</sap:WorkflowViewStateService.ViewState>'
    $vsIdx = $content.LastIndexOf($viewstateClose, $idx)
    if ($vsIdx -ge 0) {
        "Found ViewState close at idx: $vsIdx (before Assign_103 at $idx)"
        # Check that there's nothing important between vsIdx and idx (just whitespace/newlines)
        $between = $content.Substring($vsIdx + $viewstateClose.Length, $idx - $vsIdx - $viewstateClose.Length)
        "Between ViewState and Assign_103 (first 100 chars): '" + $between.Substring(0, [Math]::Min(100, $between.Length)) + "'"
        
        # Insert Variables block after the ViewState close
        $newVars = @'

                                        <Sequence.Variables>
                                          <Variable x:TypeArguments="sd:DataTable" Name="dt_HitsPage" />
                                        </Sequence.Variables>
'@
        # Only insert if not already there
        if (-not $content.Contains('Name="dt_HitsPage"')) {
            $insertPos = $vsIdx + $viewstateClose.Length
            $content = $content.Substring(0, $insertPos) + $newVars + $content.Substring($insertPos)
            "Change2 (dt_HitsPage variable): OK - inserted"
        } else {
            "Change2: dt_HitsPage already present - skipped"
        }
    } else {
        "Change2: ViewState close not found before Assign_103"
    }
} else {
    "Change2: Assign_103 NOT found"
}

# ─── CHANGE 3+4: Merge Block + Updated LogMessage ───────────────────────────
$oldLog = 'DisplayName="Log CPV-Suche TODO" sap:VirtualizedContainerService.HintSize="416,166" sap2010:WorkflowViewState.IdRef="LogMessage_18" Level="Info" Message="[&quot;[TODO] Suche CPV: &quot; &amp; currentCpvCode &amp; &quot; | TypeInto + Click + ExtractTableData hier einbauen&quot;]"'

"OldLog (LogMessage_18 TODO) present: " + $content.Contains($oldLog)

if ($content.Contains($oldLog)) {
    $mergeXaml = @'
DisplayName="Log CPV-Suche" sap:VirtualizedContainerService.HintSize="416,200" sap2010:WorkflowViewState.IdRef="LogMessage_18" Level="Info" Message="[&quot;[CPV &quot; &amp; currentCpvCode &amp; &quot;] &quot; &amp; If(dt_HitsPage IsNot Nothing, dt_HitsPage.Rows.Count, 0) &amp; &quot; Treffer | dt_Hits gesamt: &quot; &amp; dt_Hits.Rows.Count]"
'@

    $content = $content.Replace($oldLog, $mergeXaml.Trim())
    "Change3+4 (LogMessage updated): OK"
} else {
    "Change3+4: old LogMessage_18 pattern NOT found"
}

# ─── WRITE BACK ─────────────────────────────────────────────────────────────
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
"=== File written successfully ==="
"dt_HitsPage variable present in file: " + $content.Contains('Name="dt_HitsPage"')
"ExtractedData points to dt_HitsPage: " + $content.Contains('ExtractedData="[dt_HitsPage]"')
"Old TODO LogMessage gone: " + (-not $content.Contains('[TODO] Suche CPV:'))
