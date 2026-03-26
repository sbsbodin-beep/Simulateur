$ErrorActionPreference = "Stop"

$Branch = "feature/wpf-msix-simulateur"
$SolutionName = "SimulateurDonationSuccession"

function Write-Lines([string]$Path, [string[]]$Lines) {
  $dir = Split-Path $Path -Parent
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  ($Lines -join "`r`n") | Set-Content -Encoding UTF8 $Path
}

# Ensure in repo root
if (-not (Test-Path ".git")) { throw "Run this script from the repo root (folder containing .git)." }

git checkout -B $Branch | Out-Null

New-Item -ItemType Directory -Force -Path "src","tests",".github\workflows" | Out-Null

dotnet new sln -n $SolutionName | Out-Null
dotnet new classlib -n NotaireSimu.Domain -o src/NotaireSimu.Domain | Out-Null
dotnet new classlib -n NotaireSimu.Fiscalite -o src/NotaireSimu.Fiscalite | Out-Null
dotnet new classlib -n NotaireSimu.Persistence -o src/NotaireSimu.Persistence | Out-Null
dotnet new wpf     -n NotaireSimu.App -o src/NotaireSimu.App --framework net8.0-windows | Out-Null
dotnet new xunit   -n NotaireSimu.Tests -o tests/NotaireSimu.Tests | Out-Null

dotnet sln "$SolutionName.sln" add `
  "src/NotaireSimu.Domain/NotaireSimu.Domain.csproj" `
  "src/NotaireSimu.Fiscalite/NotaireSimu.Fiscalite.csproj" `
  "src/NotaireSimu.Persistence/NotaireSimu.Persistence.csproj" `
  "src/NotaireSimu.App/NotaireSimu.App.csproj" `
  "tests/NotaireSimu.Tests/NotaireSimu.Tests.csproj" | Out-Null

dotnet add "src/NotaireSimu.Fiscalite/NotaireSimu.Fiscalite.csproj" reference "src/NotaireSimu.Domain/NotaireSimu.Domain.csproj" | Out-Null
dotnet add "src/NotaireSimu.Persistence/NotaireSimu.Persistence.csproj" reference "src/NotaireSimu.Domain/NotaireSimu.Domain.csproj" | Out-Null
dotnet add "src/NotaireSimu.App/NotaireSimu.App.csproj" reference `
  "src/NotaireSimu.Domain/NotaireSimu.Domain.csproj" `
  "src/NotaireSimu.Fiscalite/NotaireSimu.Fiscalite.csproj" `
  "src/NotaireSimu.Persistence/NotaireSimu.Persistence.csproj" | Out-Null

# Domain/AppInfo.cs
Write-Lines "src/NotaireSimu.Domain/AppInfo.cs" @(
"namespace NotaireSimu.Domain;",
"",
"public static class AppInfo",
"{",
"    public const string AppDisplayName = ""Simulateur Donation & Succession"";",
"    public const string DataFolderName = ""SimulateurDonationSuccession"";",
"    public const string DataFileName = ""appstate.json"";",
"}"
)

# Domain/AppState.cs
Write-Lines "src/NotaireSimu.Domain/AppState.cs" @(
"namespace NotaireSimu.Domain;",
"",
"public sealed class AppState",
"{",
"    public string Version { get; set; } = ""0.1"";",
"    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;",
"",
"    // TODO: Famille, Patrimoine, Paramètres, Scénarios (Succession1, Succession2, Donation)",
"}",
"",
"public static class SampleData",
"{",
"    public static AppState Create() => new()",
"    {",
"        Version = ""0.1"",",
"        CreatedAt = DateTime.UtcNow",
"    };",
"}"
)

# Persistence/JsonStore.cs
Write-Lines "src/NotaireSimu.Persistence/JsonStore.cs" @(
"namespace NotaireSimu.Persistence;",
"",
"using System.Text.Json;",
"using NotaireSimu.Domain;",
"",
"public static class StoragePaths",
"{",
"    public static string GetDataDir()",
"    {",
"        var docs = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);",
"        return Path.Combine(docs, AppInfo.DataFolderName);",
"    }",
"",
"    public static string GetDataFilePath()",
"        => Path.Combine(GetDataDir(), AppInfo.DataFileName);",
"}",
"",
"public static class JsonStore",
"{",
"    private static readonly JsonSerializerOptions Options = new()",
"    {",
"        WriteIndented = true",
"    };",
"",
"    public static async Task<T> LoadOrCreateAsync<T>(Func<T> createDefault)",
"    {",
"        Directory.CreateDirectory(StoragePaths.GetDataDir());",
"        var path = StoragePaths.GetDataFilePath();",
"",
"        if (!File.Exists(path))",
"        {",
"            var def = createDefault();",
"            await SaveAsync(def);",
"            return def;",
"        }",
"",
"        var json = await File.ReadAllTextAsync(path);",
"        var obj = JsonSerializer.Deserialize<T>(json, Options);",
"        return obj ?? createDefault();",
"    }",
"",
"    public static async Task SaveAsync<T>(T obj)",
"    {",
"        Directory.CreateDirectory(StoragePaths.GetDataDir());",
"        var path = StoragePaths.GetDataFilePath();",
"        var json = JsonSerializer.Serialize(obj, Options);",
"        await File.WriteAllTextAsync(path, json);",
"    }",
"}"
)

# App/Mvvm.cs
Write-Lines "src/NotaireSimu.App/Mvvm.cs" @(
"using System.ComponentModel;",
"using System.Runtime.CompilerServices;",
"using System.Windows.Input;",
"",
"namespace NotaireSimu.App;",
"",
"public abstract class ViewModelBase : INotifyPropertyChanged",
"{",
"    public event PropertyChangedEventHandler? PropertyChanged;",
"    protected void OnPropertyChanged([CallerMemberName] string? name = null)",
"        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));",
"}",
"",
"public sealed class RelayCommand : ICommand",
"{",
"    private readonly Action _execute;",
"    private readonly Func<bool>? _canExecute;",
"",
"    public RelayCommand(Action execute, Func<bool>? canExecute = null)",
"    {",
"        _execute = execute;",
"        _canExecute = canExecute;",
"    }",
"",
"    public bool CanExecute(object? parameter) => _canExecute?.Invoke() ?? true;",
"    public void Execute(object? parameter) => _execute();",
"    public event EventHandler? CanExecuteChanged;",
"    public void RaiseCanExecuteChanged() => CanExecuteChanged?.Invoke(this, EventArgs.Empty);",
"}"
)

# App/MainViewModel.cs
Write-Lines "src/NotaireSimu.App/MainViewModel.cs" @(
"namespace NotaireSimu.App;",
"",
"using NotaireSimu.Domain;",
"using NotaireSimu.Persistence;",
"",
"public sealed class MainViewModel : ViewModelBase",
"{",
"    private AppState? _state;",
"",
"    public AppState? State",
"    {",
"        get => _state;",
"        private set { _state = value; OnPropertyChanged(); }",
"    }",
"",
"    public RelayCommand RecalculGlobalCommand { get; }",
"",
"    public MainViewModel()",
"    {",
"        RecalculGlobalCommand = new RelayCommand(RecalculGlobal);",
"        _ = LoadAsync();",
"    }",
"",
"    private async Task LoadAsync()",
"    {",
"        State = await JsonStore.LoadOrCreateAsync(SampleData.Create);",
"    }",
"",
"    private void RecalculGlobal()",
"    {",
"        // TODO: recalcul global (succession 1, succession 2, donation, synthèse)",
"    }",
"}"
)

# App/MainWindow.xaml
Write-Lines "src/NotaireSimu.App/MainWindow.xaml" @(
"<Window x:Class=""NotaireSimu.App.MainWindow""",
"        xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""",
"        xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""",
"        Title=""Simulateur Donation &amp; Succession"" Height=""780"" Width=""1200"">",
"    <DockPanel>",
"        <ToolBar DockPanel.Dock=""Top"">",
"            <Button Content=""Recalcul global"" Padding=""12,6"" Command=""{Binding RecalculGlobalCommand}"" />",
"        </ToolBar>",
"        <TabControl>",
"            <TabItem Header=""Famille""><Grid Margin=""12""><TextBlock Text=""À implémenter : gestion des personnes."" /></Grid></TabItem>",
"            <TabItem Header=""Patrimoine""><Grid Margin=""12""><TextBlock Text=""À implémenter : actifs/passifs."" /></Grid></TabItem>",
"            <TabItem Header=""Paramètres""><Grid Margin=""12""><TextBlock Text=""À implémenter : hypothèses."" /></Grid></TabItem>",
"            <TabItem Header=""Succession 1""><Grid Margin=""12""><TextBlock Text=""À implémenter : scénario succession 1."" /></Grid></TabItem>",
"            <TabItem Header=""Succession 2""><Grid Margin=""12""><TextBlock Text=""À implémenter : scénario succession 2."" /></Grid></TabItem>",
"            <TabItem Header=""Donation jour J""><Grid Margin=""12""><TextBlock Text=""À implémenter : donation."" /></Grid></TabItem>",
"            <TabItem Header=""Synthèse""><Grid Margin=""12""><TextBlock Text=""À implémenter : synthèse."" /></Grid></TabItem>",
"        </TabControl>",
"    </DockPanel>",
"</Window>"
)

# App/MainWindow.xaml.cs
Write-Lines "src/NotaireSimu.App/MainWindow.xaml.cs" @(
"namespace NotaireSimu.App;",
"",
"public partial class MainWindow",
"{",
"    public MainWindow()",
"    {",
"        InitializeComponent();",
"        DataContext = new MainViewModel();",
"    }",
"}"
)

# README.md
$readme = "# Simulateur Donation & Succession`r`n`r`n" +
          "Application Windows (WPF .NET 8) visant à simuler des scénarios de donation et successions avec stockage local JSON (sans Excel, sans base).`r`n`r`n" +
          "Stockage : `Documents\SimulateurDonationSuccession\appstate.json``r`n`r`n" +
          "Run :`r`n" +
          "    dotnet run --project .\src\NotaireSimu.App\NotaireSimu.App.csproj`r`n"

$readme | Set-Content -Encoding UTF8 "README.md"

# Workflow
Write-Lines ".github/workflows/build.yml" @(
"name: build",
"",
"on:",
"  push:",
"  pull_request:",
"",
"jobs:",
"  build:",
"    runs-on: windows-latest",
"    steps:",
"      - uses: actions/checkout@v4",
"      - uses: actions/setup-dotnet@v4",
"        with:",
"          dotnet-version: '8.0.x'",
"      - run: dotnet build ./SimulateurDonationSuccession.sln -c Release"
)

git status
git add .
git commit -m "Bootstrap WPF (.NET 8) + MVVM + onglets + persistance JSON"
git push -u origin $Branch

Write-Host "OK. Lance: dotnet run --project .\src\NotaireSimu.App\NotaireSimu.App.csproj"