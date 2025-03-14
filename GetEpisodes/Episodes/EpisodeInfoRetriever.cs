using HtmlAgilityPack;
using Microsoft.Extensions.Configuration;

namespace GetEpisodes.Episodes
{
	class EpisodeInfoRetriever
	{
		private readonly string episodeSelector;
		private readonly string dataIdAttribute;

		public EpisodeInfoRetriever(IConfigurationSection config)
		{
			episodeSelector = config[nameof(episodeSelector)];
			dataIdAttribute = config[nameof(dataIdAttribute)];
		}

		public IReadOnlyCollection<EpisodeInfo> Retrieve(HtmlDocument doc)
		{
			var episodes = doc.DocumentNode.SelectNodes(episodeSelector);
			var result = new List<EpisodeInfo>(episodes.Count);
			foreach (var episode in episodes)
			{
				result.Add(new()
				{
					Number = int.Parse(episode.InnerText.Split(' ')[0]),
					DataId = int.Parse(episode.GetAttributeValue(dataIdAttribute, string.Empty))
				});
			}

			return result;
		}
	}
}
