namespace NotaireSimu.Domain;

public sealed class AppState
{
    public string Version { get; set; } = "0.1";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // TODO: Famille, Patrimoine, Paramètres, Scénarios (Succession1, Succession2, Donation)
}

public static class SampleData
{
    public static AppState Create() => new()
    {
        Version = "0.1",
        CreatedAt = DateTime.UtcNow
    };
}
