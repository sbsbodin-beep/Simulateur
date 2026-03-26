namespace NotaireSimu.App;

using NotaireSimu.Domain;
using NotaireSimu.Persistence;

public sealed class MainViewModel : ViewModelBase
{
    private AppState? _state;

    public AppState? State
    {
        get => _state;
        private set { _state = value; OnPropertyChanged(); }
    }

    public RelayCommand RecalculGlobalCommand { get; }

    public MainViewModel()
    {
        RecalculGlobalCommand = new RelayCommand(RecalculGlobal);
        _ = LoadAsync();
    }

    private async Task LoadAsync()
    {
        State = await JsonStore.LoadOrCreateAsync(SampleData.Create);
    }

    private void RecalculGlobal()
    {
        // TODO: recalcul global (succession 1, succession 2, donation, synthèse)
    }
}
