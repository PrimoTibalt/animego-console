using HtmlAgilityPack;
using Microsoft.Extensions.Configuration;
using System.Net;

namespace GetEpisodes.Translations
{
	internal class TranslationsInfoRetriever
	{
		private readonly string elementWithDataDubbingSelector;
		private readonly string elementWithPlayerSelector;
		private readonly string elementWithPlayerNameSelector;
		private readonly string elementWithDubbingNameSelector;

		public TranslationsInfoRetriever(IConfigurationSection selectors)
		{
			elementWithDataDubbingSelector = selectors[nameof(elementWithDataDubbingSelector)];
			elementWithPlayerSelector = selectors[nameof(elementWithPlayerSelector)];
			elementWithDubbingNameSelector = selectors[nameof(elementWithDubbingNameSelector)];
			elementWithPlayerNameSelector = selectors[nameof(elementWithPlayerNameSelector)];
		}

		public List<TranslationInfo> Retrieve(HtmlDocument doc)
		{
			var nodes = doc.DocumentNode.SelectNodes(elementWithDataDubbingSelector);
			var translationToDataDubbing = nodes.Select(node => (
					Name: node.SelectSingleNode(elementWithDubbingNameSelector).InnerText.Trim(),
					DubbingId: node.GetAttributeValue<int>("data-dubbing", 0)
				)
			).ToList();
			List<TranslationInfo> translationInfos = new(translationToDataDubbing.Count);
			foreach (var pair in translationToDataDubbing)
			{
				var info = new TranslationInfo();
				info.Name = pair.Name;
				var preparedSelector = elementWithPlayerSelector.Replace("{data-dubbing}", pair.DubbingId.ToString());
				var elementsWithPlayers = doc.DocumentNode.SelectNodes(preparedSelector);
				foreach (var player in elementsWithPlayers)
				{
					var playerName = player.SelectSingleNode(elementWithPlayerNameSelector).InnerText.Trim();
					var playerUrl = WebUtility.HtmlDecode(player.GetAttributeValue<string>("data-player", string.Empty));
					info.Players ??= new();
					info.Players.Add((playerName, playerUrl));
				}

				translationInfos.Add(info);
			}

			return translationInfos;
		}
	}
}