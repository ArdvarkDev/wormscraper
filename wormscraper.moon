http = require 'socket.http'

grabChapter = (dir, link, number) ->
	
	print 'grabbing ' .. link
	body = http.request link

	body = body\gsub 'https://s1.wp.com/wp--content/mu--plugins/wpcom--smileys/', '../Images/'
	body = body\gsub 'id="internal--source--marker_0.43876651558093727"', ''
	body = body\gsub 'style="text--align:left;" align="CENTER"', ''
	body = body\gsub 'align="LEFT"', ''
	body = body\gsub 'align="left"', ''
	body = body\gsub 'align="CENTER"', 'style="text-align:center;"'
	body = body\gsub 'align="center"', 'style="text-align:center;"'


	lines = {}
	for line in body\gmatch '[^\n]+'
		table.insert lines, line

	title = ''
	next = ''
	file = nil
	
	for line in *lines
	
		_, pos = line\find '<meta property="og:title" content="'
		if pos
			title = line\sub pos+1, -5
		
		pos = line\find '>Next Chapter<'
		unless pos then pos = line\find '> Next Chapter<'
		
		if pos
			pos -= 2
			
			start = pos
			while start > 1
				if line\sub(start, start) == '"'
					break
				start -= 1
			
			next = line\sub start+1, pos
	
	file = io.open dir .. '/chapter' .. string.format('%03d', number) .. '.xhtml', 'w'
	j = 0
	
	
	file\write [[
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
	<title>Worm</title>
	<meta charset="utf-8"/>
</head>
<body>
	<section class="body-rw Chapter-rw" epub:type="bodymatter chapter">
		<header>
			<h1>]] .. title .. '</h1>\n\t\t</header>\n'
	
	for line in *lines
		if line\find('Next Chapter<') or line\find('Last Chapter<')
			j += 1
			if j > 1
				break
			continue
			
		if line\find('</del></p>') or line\find('<p>&nbsp;</p>')
			continue
	
		if j > 0
			file\write '\t\t' .. line .. '\n'

	file\write '\t</section>\n</body>\n</html>'

	file\close!
	
	return next, title


os.execute 'rm -r book/'
os.execute 'rm book.epub'
os.execute 'mkdir book/'
os.execute 'mkdir book/META-INF/'
os.execute 'mkdir book/OPS/'
os.execute 'mkdir book/OPS/Text'
os.execute 'cp -r Images/ book/OPS/'

link = 'https://parahumans.wordpress.com/2011/06/11/1-1/'


chapters = {}

i = 0
while link ~= ''
	i += 1
	link, title = grabChapter 'book/OPS/Text', link, i
	
	name = title\match '%S+'
	number = title\sub name\len! + 2

	chapter = 
		name: name
		major: number
		minor: ''
		filename: 'chapter' .. i .. '.html'
		
	if title\find '½'
		chapter.major = number\gsub '½', '&#189;'
		chapter.minor = ''
	
	unless name\find 'Interlude'
		chapter.major = number\sub 1, number\find('[.]')-1
		chapter.minor = number\sub number\find('[.]')+1
		
	-- if title == 'Interlude: End'
	-- 	chapter.major = 
		
	chapters[i] = chapter

	-- if i > 5
	-- 	break



print 'done fetching'


f = io.open 'book/mimetype', 'w'
f\write 'application/epub+zip'
f\close!

f = io.open 'book/META-INF/container.xml', 'w'
f\write [[
<?xml version="1.0" encoding="UTF-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
   <rootfiles>
      <rootfile full-path="OPS/package.opf" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>
]]
f\close!

f = io.open 'book/OPS/package.opf', 'w'
f\write [[
<?xml version='1.0' encoding='utf-8'?>
<package xmlns="http://www.idpf.org/2007/opf" xmlns:svg="http://www.w3.org/2000/svg" xmlns:epub="http://www.idpf.org/2007/ops" version="3.0" unique-identifier="pub-id" xml:lang="en">
	<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
		<dc:title>Worm</dc:title>
		<dc:creator id="creator01">Wildbow</dc:creator>
		<dc:language>en</dc:language>
		<dc:identifier id="pub-id">wildbow.worm</dc:identifier>
		<meta property="dcterms:modified">]] .. os.date("%Y-%m-%dT%H:%M:%SZ") .. [[</meta>
	</metadata>
	<manifest>
		<item id="cover" href="cover.xhtml" media-type="application/xhtml+xml"/>
]]


for i, chapter in ipairs(chapters)
	f\write string.format('\t\t<item id="chapter%03d" href="Text/chapter%03d.xhtml" media-type="application/xhtml+xml"/>\n', i, i)

f\write [[
		<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
		<item id="o_O" href="Images/o_O.svg" media-type="image/svg+xml"/>
		<item id="cover_image" href="Images/cover.jpeg" media-type="image/jpeg"/>
	</manifest>
	<spine>
		<itemref idref="cover" linear="yes"/>
]]

for i, chapter in ipairs(chapters)
	f\write string.format('\t\t<itemref idref="chapter%03d" linear="yes"/>\n', i)

f\write [[
		<itemref idref="nav" linear="no"/>
	</spine>
</package>
]]

f\close!


f = io.open 'book/OPS/cover.xhtml', 'w'
f\write [[
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
	<title>Worm</title>
	<meta charset="utf-8"/>
</head>
<body>
	<p style="text-align:center;"><img alt="Cover Image" src="Images/cover.jpeg" style="height: 100%;"/></p>
</body>
</html>
]]
f\close!

f = io.open 'book/OPS/nav.xhtml', 'w'
f\write [[
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
	<meta charset="utf-8" />
	<title>Table of Contents</title>
</head>
<body>
	<nav epub:type="toc" id="toc">
		<h1 class="title">Table of Contents</h1>
		
		<ol>
			<li><a href="cover.xhtml">Cover</a></li>
]]

lastMajor = ''
for i, chapter in ipairs(chapters)

	unless chapter.name == 'Interlude'
		unless lastMajor == chapter.major
			unless lastMajor == ''
				f\write '\t\t\t</ol>\n\t\t\t\t</li>\n'
				
			f\write string.format('\t\t\t<li><a href="Text/chapter%03d.xhtml">Arc %s: %s</a>\n', i, chapter.major, chapter.name)
			f\write '\t\t\t\t<ol>\n'
			
		lastMajor = chapter.major
		
	
	unless chapter.minor == ''
		f\write string.format('\t\t\t\t\t<li><a href="Text/chapter%03d.xhtml">%s.%s</a></li>\n', i, chapter.major, chapter.minor)
	else
		f\write string.format('\t\t\t\t\t<li><a href="Text/chapter%03d.xhtml">%s %s</a></li>\n', i, chapter.name, chapter.major)
	

f\write [[
				</ol>
			</li>
		</ol>
	</nav>
</body>
</html>
]]

f\close!

-- zip
os.execute 'epubcheck book/ --mode exp --save'

