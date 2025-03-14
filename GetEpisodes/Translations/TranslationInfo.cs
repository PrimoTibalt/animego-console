namespace GetEpisodes.Translations
{
	public sealed class TranslationInfo
	{
		public string Name { get; set; }
		public List<(string PlayerName, string PlayerUrl)> Players { get; set; }
	}
}
