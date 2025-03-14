using Microsoft.Extensions.Configuration;
using HtmlAgilityPack;
using static System.Console;
using System.Text;
using GetEpisodes.Translations;
using GetEpisodes.Episodes;

namespace GetEpisodes
{
	internal class Program
	{
		async static Task Main(string[] args)
		{
			OutputEncoding = Encoding.UTF8;

			var configuration = new ConfigurationBuilder()
				.AddJsonFile("appsettings.json")
				.Build();

			var selectors = configuration.GetSection("Selectors");
			var doc = new HtmlDocument();

			doc.LoadHtml(args[1]);
			switch (args[0])
			{
				case "episodes":
					var episodeInfoRetriever = new EpisodeInfoRetriever(selectors);
					var episodes = episodeInfoRetriever.Retrieve(doc);
					for (var i = 0; i < episodes.Count; i++)
					{
						var episode = episodes.ElementAt(i);
						Out.Write($"{episode.Number},{episode.DataId}");
						if (i < episodes.Count - 1)
							Out.Write(";");
					}

					break;
				case "translations":
					var translationsInfoRetriever = new TranslationsInfoRetriever(selectors);
					var translations = translationsInfoRetriever.Retrieve(doc);
					for (var i = 0; i < translations.Count; i++)
					{
						var translation = translations.ElementAt(i);
						var linksCombination = translation.Players.Select(player =>
						$"{player.PlayerName}:{player.PlayerUrl}").Aggregate((prev, current) =>
						prev + "||" + current);
						Out.Write($"{translation.Name},{linksCombination}");
						if (i < translations.Count - 1)
							Out.Write(";");
					}

					break;
			}
		}
	}
}
