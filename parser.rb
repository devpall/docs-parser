require "htmlentities"
require "open-uri"
require "nokogiri"
require "cgi"

# TODO: Change anchors in the index to use texts such as "guia-rapido-de-uso"
# TODO: Try to make the index float at the left

# Call script with:
# * ruby parser.rb rnp
# * ruby parser.rb ufrgs

if ARGV and ARGV[0]
  if ARGV[0] == "ufrgs"
    type = "ufrgs"
  elsif ARGV[0] == "rnp"
    type = "rnp"
  else
    type = "ufrgs"
  end
else
  type = "ufrgs"
end

puts "Docs for #{type}..."

output = "out.html"
if type == "ufrgs"
  url = "https://docs.google.com/document/d/1fUye_omrE5jgMnljL9ZuvK-BJUhyRM6dCQ8KTtunC70"
else # rnp
  url = "https://docs.google.com/document/d/18ECQVc73ItVJ_VAR0_ki8mG4b3BYFM3onEcaOMwkUWE"
end

default_style = <<-HTML
  <style type="text/css">
    #menu {
      float: left; top: 150px; background: #f6f6f6; width: 230px; border-radius: 4px; border: 1px solid #eee;
      padding: 0 10px 5px 10px;
    }
    .docs-content { /* margin-left: 280px; float:left; padding-left: 270px; width: 700px; */ }
    .docs-content img { border-radius: 2px; margin: 20px 10px; box-shadow: 3px 3px 10px rgba(0, 0, 0, 0.3); max-width: 600px; }
    .disclaimer { color: red; }
    #menu.affix { top: 20px; }
    a.anchor { margin-top: 20px; }
  </style>
  HTML

doc = Nokogiri::HTML(open("#{url}/pub"), nil, 'UTF-8')

# We want the second <style> block
style = doc.xpath("//style")[1]
unless style.nil?
  style.content = style.content.gsub(/\.title{[^}]*}/, "")
  style.content = style.content.gsub(/h1{[^}]*}/, "")
end

# Fix images, the src is relative in the doc, but shouldn't
doc.css("img").each do |img|
  unless img.attributes["src"].nil?
    img.attributes["src"].value = "#{url}/#{img.attributes["src"].value}"
  end
end

# Remove the title
doc.xpath('//*[contains(@class, "title")]').remove

# Remove empty tags
def is_blank?(node)
  node.content.strip == '' and node.children.length == 0
end
doc.css("span").select{ |p| is_blank?(p) }.each{ |node| node.remove }
doc.css("p").select{ |p| is_blank?(p) }.each{ |node| node.remove }

# The content we want
content = doc.xpath("//*[preceding-sibling::style]")

# Wrap the content in a class we can style
content = Nokogiri.make("<div class='docs-content'>#{content.to_html}</div>")

# Write it
File.open(output, "w:UTF-8") do |file|
  file.write(HTMLEntities.new.decode(style.to_s))
  file.write(HTMLEntities.new.decode(default_style.to_s))
  file.write(HTMLEntities.new.decode(content.to_s))
end
