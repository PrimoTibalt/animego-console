using Microsoft.Extensions.Configuration;
using HtmlAgilityPack;
using static System.Console;
using System.Text;

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

			switch (args[0])
			{
				case "episodes":
					var selectors = configuration.GetSection("Selectors");
					var doc = new HtmlDocument();

					doc.LoadHtml(args[1]);
					var retriever = new EpisodeInfoRetriever(selectors);
					var data = retriever.Retrieve(doc);
					for (var i = 0; i < data.Count; i++)
					{
						var episode = data.ElementAt(i);
						Out.Write($"{episode.Number},{episode.DataId}");
						if (i < data.Count - 1)
							Out.Write(";");
					}
					break;
				case "translations":
					break;
			}
		}
	}
}
