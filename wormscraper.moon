http = require 'socket.http'

if arg[1] == nil or arg[1] == '' or arg[2] == nil or arg[2] == ''
	print 'Usage: ' .. arg[0] .. ' <name> <first link>'
	os.exit!


-- link = 'https://pactwebserial.wordpress.com/2013/12/17/bonds-1-1/'
book = arg[1]
link = arg[2]

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
	body = body\gsub '<span style="font--size:15px;font--style:inherit;line--height:1.625;">', '<span>'
	body = body\gsub 'id="result_box"', ''
	body = body\gsub '<p style="text--align:left;">\n', ''
	body = body\gsub '<p style="text--align:center;">\n', ''
	body = body\gsub '<br />\n</strong></p>', '<br /></strong></p>'
	body = body\gsub '<strong>Autumn<br />\n', '<strong>Autumn<br /></strong></p>\n'
	
	
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
		
		pos = line\find '">Next Chapter<'
		unless pos then pos = line\find '/"><strong>Next'
		unless pos then pos = line\find '/">Next'
		unless pos then pos = line\find '/"> Next'
		
		if pos and next == ''
			pos -= 1
			
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
		if line\find('/">Next') or line\find('/"> Next') or line\find('Last Chapter<') or line\find('>Previous<') or line\find('</div><!---- .entry--content ---->')
			j += 1
			if j > 1
				break
			continue
			
		if line\find('</del></p>') or line\find('<p>&nbsp;</p>') or line\gsub('%s+', '') == '</strong></p>'
			continue
	
		if j > 0
			file\write '\t\t' .. line .. '\n'

	file\write '\t</section>\n</body>\n</html>'

	file\close!
	
	return next, title


os.execute 'rm -r book/'
os.execute 'mkdir book/'
os.execute 'mkdir book/META-INF/'
os.execute 'mkdir book/OPS/'
os.execute 'mkdir book/OPS/Text'
os.execute 'cp -r Images/ book/OPS/'

chapters = {}

i = 0
while link ~= '' and link ~= 'next'
	i += 1
	link, title = grabChapter 'book/OPS/Text', link, i
	
	title = title\gsub('[(]Arc ', '')\gsub('Arc ', '')\gsub('[(]Bonus', '')\gsub('&#8211; Boys[)]', '')\gsub('&#8211; Girls[)]', '')\gsub('[)]', '')\gsub('&#8211;', '')
	-- print title
	
	hashalf = title\find '½'
	if hashalf then title = title\gsub '½', ''
	
	name = title
	number = ''
	while tonumber(number) == nil and tonumber(number\sub(1, number\len!-1)) == nil and name\match('%S+') ~= nil
		number = name\match '%S+'
		name = name\sub number\len!+1
		-- print '\'' .. name .. '\'', '\'' .. number .. '\''
	
	
	name = title\sub 1, title\find(number) - 1
	while name\sub(name\len!, name\len!) == ' '
		name = name\sub(1, name\len!-1)
		
	if tonumber(number) == nil and tonumber(number\sub(1, number\len!-1)) == nil
		name = title
		number = ''
		
	if name\sub(name\len!) == ':'
		name = name\sub 1, name\len!-1

	chapter = 
		name: name
		major: number
		minor: ''
		filename: 'chapter' .. i .. '.html'
		
	if title\find '½'
		chapter.major = number\gsub '½', '&#189;'
	
	switch name
		
		when 'Teneral e.'
			chapter.name = 'Teneral'
			chapter.major = 'e'
			chapter.minor = number
		
		when 'Epilogue'
			chapter.name = 'Epilogue'
			chapter.major = ''
			
		else
			if number\find('[.]')
				chapter.major = number\sub 1, number\find('[.]')-1
				chapter.minor = number\sub number\find('[.]')+1
				
			if title\find('e[.]')
				chapter.major = 'e'
	
	
	if hashalf and chapter.minor == '' then chapter.major ..= '½'
	chapters[i] = chapter
	
	
	-- print '\'' .. chapter.name .. '\'', '\'' .. chapter.major .. '\'', '\'' .. chapter.minor .. '\''
	
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
		<dc:title>]] .. book\gsub('^%l', string.upper) .. [[</dc:title>
		<dc:creator id="creator01">Wildbow</dc:creator>
		<dc:language>en</dc:language>
		<dc:identifier id="pub-id">wildbow.]] .. book .. [[</dc:identifier>
		<meta property="dcterms:modified">]] .. os.date("%Y-%m-%dT%H:%M:%SZ") .. [[</meta>
	</metadata>
	<manifest>
]]


for i, chapter in ipairs(chapters)
	f\write string.format('\t\t<item id="chapter%03d" href="Text/chapter%03d.xhtml" media-type="application/xhtml+xml"/>\n', i, i)

f\write [[
		<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
		<item id="o_O" href="Images/o_O.svg" media-type="image/svg+xml"/>
	</manifest>
	<spine>
]]

for i, chapter in ipairs(chapters)
	f\write string.format('\t\t<itemref idref="chapter%03d" linear="yes"/>\n', i)

f\write [[
		<itemref idref="nav" linear="no"/>
	</spine>
</package>
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
]]

lastMajor = ''
hasepilogue = false

for i, chapter in ipairs(chapters)

	if chapter.name == 'Epilogue'
		hasepilogue = true
		f\write '\t\t\t</ol>\n\t\t\t\t</li>\n'
		f\write string.format('\t\t\t<li><a href="Text/chapter%03d.xhtml">Epilogue</a></li>\n', i)
		continue


	unless chapter.minor == ''
		unless lastMajor == chapter.major
			unless lastMajor == ''
				f\write '\t\t\t\t</ol>\n\t\t\t</li>\n'
				
			f\write string.format('\t\t\t<li><a href="Text/chapter%03d.xhtml">Arc %s: %s</a>\n', i, chapter.major, chapter.name)
			f\write '\t\t\t\t<ol>\n'
		
		f\write string.format('\t\t\t\t\t<li><a href="Text/chapter%03d.xhtml">%s.%s</a></li>\n', i, chapter.major, chapter.minor)
			
		lastMajor = chapter.major
	
	else
		f\write string.format('\t\t\t\t\t<li><a href="Text/chapter%03d.xhtml">%s %s</a></li>\n', i, chapter.name, chapter.major)
	

unless hasepilogue
	f\write '\t\t\t\t</ol>\t\t\t</li>\n'

f\write [[
		</ol>
	</nav>
</body>
</html>
]]

f\close!

-- zip
os.execute 'epubcheck book/ --mode exp --save'
os.execute 'mv book.epub ' .. book\gsub('^%l', string.upper) .. '.epub'

