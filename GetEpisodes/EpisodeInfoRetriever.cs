using HtmlAgilityPack;
using Microsoft.Extensions.Configuration;

namespace GetEpisodes
{
	class EpisodeInfoRetriever
	{


		public EpisodeInfoRetriever(IConfigurationSection config)
		{
			
		}

		public IReadOnlyCollection<EpisodeInfo> Retrieve(HtmlDocument doc)
		{
			var episodes = doc.DocumentNode.SelectNodes(@"//option[@value]");
			var result = new List<EpisodeInfo>(episodes.Count);
			foreach (var episode in episodes)
			{
				result.Add(new()
				{
					Number = int.Parse(episode.InnerText.Split(' ')[0]),
					DataId = int.Parse(episode.GetAttributeValue("value", string.Empty))
				});
			}

			return result;
		}
	}
}
