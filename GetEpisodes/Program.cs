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
		static void Main(string[] args)
		{
			InputEncoding = Encoding.UTF8;
			OutputEncoding = Encoding.UTF8;

			var configuration = new ConfigurationBuilder()
				.AddJsonFile("appsettings.json")
				.Build();

			var selectors = configuration.GetSection("Selectors");
			var doc = new HtmlDocument();

			var html = args[1];
			if (args.Count() > 2)
				html = string.Join(string.Empty, args[1..]);

			doc.LoadHtml(html);
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
				case "search":
					var animes = doc.DocumentNode.SelectNodes(selectors["animeSelector"]) ?? (IList<HtmlNode>)[];
					for (var i = 0; i < animes.Count; i++)
					{
						var anime = animes.ElementAt(i);
						var href = anime.GetAttributeValue<string>("href", string.Empty).Trim();
						Out.Write($"{anime.InnerText.Trim()}||{href}");
						if (i < animes.Count - 1)
							Out.Write(";");
					}

					break;
			}
		}
	}
}
