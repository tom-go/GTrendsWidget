#import "TrendsData.h"

@interface TrendsData()
@property(nonatomic, retain) NSURLConnection *connection_;
@property(nonatomic, retain) NSMutableData *rawData;
@property(nonatomic, copy)	 NSString *currentElement;
@property(nonatomic, retain) NSMutableString *title;
@property(nonatomic, retain) NSMutableString *landingPage;
@property(nonatomic, retain) NSMutableString *pubDate;
@property(nonatomic, retain) NSMutableString *traffic;
@property(nonatomic, retain) NSMutableDictionary *item;
@end
@implementation TrendsData 
- (id)init {
	self = [super init];
	if( self ) {
	}
	return self;
}

- (void)dealloc {

	[_trendsURL release];
	[_trends release];
	_delegate = nil;

	[_currentElement release];
	[_title release];
	[_landingPage release];
	[_pubDate release];
	[_traffic release];
	[_item release];

	[super dealloc];
}

- (void)updateTrends:(BOOL)forceReloading {
	if( !forceReloading ) {
		if([[NSFileManager defaultManager] fileExistsAtPath:CACHEPATH]) {
			[self getCachedTrends];
			return;
		}
	}
	[self.delegate willBeginLoadingTrends];
	[self getCurrentTrends];
}

- (void) getCurrentTrends {
	NSURL *feedURL = [NSURL URLWithString:self.trendsURL];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:feedURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
	[[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];

	self.connection_ = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if( self.connection_ ) {
		self.rawData = [NSMutableData data];
	}
	[request release];
}

- (void)getCachedTrends {
	self.trends = [NSArray arrayWithContentsOfFile:CACHEPATH];
	[self.delegate didFinishLoadingTrends];
}

- (void)appendRanks {
	NSArray *cacheArray = [NSArray arrayWithContentsOfFile:CACHEPATH];
	self.hasCachedRanking = cacheArray ? YES : NO;
	self.rankingUpdated = NO;
	self.needsFullUpdate  = YES;
	int rank = 1;

	for(NSMutableDictionary *elements in self.trends) {
		[elements setObject:[NSString stringWithFormat:@"%d", rank] forKey:@"rank"];
		if(self.hasCachedRanking) {
			int prevRank = 1;
			for( NSDictionary *cachedItem in cacheArray ) {
				if( [[elements objectForKey:@"title"] isEqualToString:[cachedItem objectForKey:@"title"]] &&
				   ([[elements objectForKey:@"pubDate"] isEqualToString:[cachedItem objectForKey:@"pubDate"]] || ![cachedItem objectForKey:@"pubDate"]) ) {
					[elements setObject:[NSString stringWithFormat:@"%d", prevRank] forKey:@"prev_rank"];
					if( rank != prevRank ) {
						self.rankingUpdated = YES;
					}
					self.needsFullUpdate = NO;
					break;
				}
				prevRank++;
			}
		}
		rank++;
	}
	// if there was no update, use cached data as the latest ranking.
	if( self.hasCachedRanking && !self.rankingUpdated ) {
		if(!self.needsFullUpdate) {
			[self getCachedTrends];
		}
	}
}

#pragma mark -
#pragma mark NSURLConnection
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[self.rawData setLength:0];
}

-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)receiveData {
	[self.rawData appendData:receiveData];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
	[self performSelector:@selector(parseTrends) withObject:nil afterDelay:0];
	[self.connection_ release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self.delegate performSelector:@selector(didFailLoadingTrendsWithError:) withObject:error afterDelay:0];
	[self.connection_ release];
	[self.rawData release];
}

#pragma mark -
#pragma mark parse xml data
- (void) parseTrends {

	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.rawData];
	[parser setDelegate:self];
	[parser parse];

	[parser release];
	[self.rawData release];

	[self.delegate didFinishLoadingTrends];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	self.trends = [[[NSMutableArray alloc] init] autorelease];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{

	self.currentElement = elementName;

	if ([self.currentElement isEqualToString:@"item"]) {
		self.item = [NSMutableDictionary dictionary];
		self.title = [NSMutableString string];
		self.landingPage = [NSMutableString string];
		self.pubDate = [NSMutableString string];
		self.traffic = [NSMutableString string];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{

	if ([self.currentElement isEqualToString:@"title"]){
		if([[self.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
			[self.title appendString:string];
		}
	}else if([self.currentElement isEqualToString:@"pubDate"]){
		if([[self.pubDate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
			[self.pubDate appendString:string];
		}
	}else if([self.currentElement isEqualToString:@"ht:news_item_url"]){
		if([[self.landingPage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
			[self.landingPage appendString:string];
		}
	}else if([self.currentElement isEqualToString:@"ht:approx_traffic"]){
		if([[self.traffic stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
			[self.traffic appendString:string];
		}
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

	if ([elementName isEqualToString:@"item"]) {

		[self.item setObject:self.title forKey:@"title"];
		[self.item setObject:self.pubDate forKey:@"pubDate"];
		[self.item setObject:self.landingPage forKey:@"landing_page"];
		[self.item setObject:self.traffic forKey:@"traffic"];

		[self.trends addObject:self.item];
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {

	if( self.trends.count == 0 ) {
		[self.trends release];
	}
	else {
		[self appendRanks];
	}
}
@end