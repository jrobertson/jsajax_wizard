#!/usr/bin/env ruby

# file: jsajax_wizard.rb

# description: Makes building an AJAX web page easier than 
#              copying and pasting an example.
# examples:
#
# jaw = JsAjaxWizard.new
#
#
# AJAX triggered from a button press
# jaw.add_request server: 'hello', element: {type: 'button', 
#         event: 'onclick'}, target_element: {id: 'demo', property: :innerHTML}
#
# AJAX triggered from an onkeyup event
# jaw.add_request server: 'hello', element: {type: 'text'}, 
#         target_element: {id: 'demo', property: :innerHTML}
#
# AJAX triggered from a timer event
# jaw.add_request server: 'hello', element: {type: 'timer', 
#         interval: '5000'}, target_element: {id: 'demo', property: :innerHTML}

# 03 Oct 2019 : An HTML document can be passed in containing an
#               AJAX placeholder e.g. 
#            <button onclick='$[x][/someurl/]'></button><div id='demo'>$x</div>
#

# AJAX triggered from a button press with the text response passed to eval
# jaw.add_request server: 'hello', element: {type: 'button', event: 'onclick'}, target_eval: true

# AJAX triggered from a speech recognition result
# jaw.add_request server: 'hello', trigger: 'recognition.onresult', target_eval: true




require 'rexle'
require 'rxfhelper'
require 'rexle-builder'

class JsAjaxWizard
  using ColouredText

  def initialize(html='', debug: false)

    @html, @debug = RXFHelper.read(html).first, debug        
    @requests = []
    
    # search for AJAX placeholders
    scan_requests(@html)    

  end

  def add_request(server: '', element: {}, trigger: nil, target_element: {}, 
                  target_eval: false)
    type = element.any? ? [:element, element] : [:trigger, trigger]
    @requests << [server, type, target_element, target_eval ]
  end

  def to_html()
    
    html = @html.empty? ? build_html : @html
    
    puts 'html: ' + html.inspect if @debug
    
    doc = Rexle.new(html)
    puts 'doc.xml: ' + doc.xml(pretty: true) if @debug
    add_events(doc)
    js = build_js(doc)
    doc.root.element('body').add(Rexle.new(js))    
    
    doc.xml    
  end

  private
  
  def add_element_function(element, i, server, target, target_eval)
    
    puts ('element: ' + element.inspect).debug if @debug
    puts '::' + [element, i, server, target, target_eval].inspect if @debug
    
    a = []
    
    a << if element.is_a?(Hash) then
    
      if element[:type] == 'text' then
    
        if element[:event].to_sym == :on_enter then
      "
function ajaxCall#{i+1}(keyCode, e) {

if (keyCode==13){
  ajaxRequest('#{server}' + e.value, ajaxResponse#{i+1})
}  

}
"
        else
      "
function ajaxCall#{i+1}(e) {
  ajaxRequest('#{server}' + e.value, ajaxResponse#{i+1})
}
"
        end
        
      elsif element[:type] == 'timer'
      "
setInterval(
function() {
  ajaxRequest('#{server}', ajaxResponse#{i+1})
}, #{element[:interval]});
"        
      else
"
function ajaxCall#{i+1}() {
  ajaxRequest('#{server}', ajaxResponse#{i+1})
}
"  
      end
      
    else
      
 "
function ajaxCall#{i+1}(s) {
  ajaxRequest('#{server}' + escape(s), ajaxResponse#{i+1})
}
"     
    end

a << "
function ajaxResponse#{i+1}(xhttp) {
"      

    if target.is_a?(Hash) and target[:id] then
      
      a << "  document.getElementById('#{target[:id]}')" + 
          ".innerHTML = xhttp.responseText;"
    end

    if target_eval then
      
      a << "  eval(xhttp.responseText);"
      
    end

a << "
}
"      

    a.join

  
  end
  
  def add_events(doc)    
    
    @requests.each.with_index do |x,i|
      
      puts ('request x: ' + x.inspect).debug if @debug
      
      method(('modify_' + x[1].first.to_s).to_sym).call(x[1].last, doc, i)
            
    end
    
    doc
  end

  def build_elements()

    html = @requests.map.with_index do |x,i|

      raw_e, e2 = x[1..-1]
      
      e = raw_e.last
      
      # e = element e.g. {type: 'button', event: 'onclick'} 
      # e2 = target_element: {id: '', property: :innerHTML}

      a = if e[:type].to_s == 'button' then
      
        ["<button type='button''>Change Content</button>"]
        
      elsif e[:type].to_s == 'text' then
        
        ["<input type='text'/>"]
        
      else
        ['']
      end
      
      a << "<div id='%s'></div>" % [e2[:id]] if e2.is_a? Hash
      a.join("\n")

    end

    r = html.join("\n")
    puts 'r: ' + r.inspect if @debug
    r

  end
  
  def build_html()

    RexleBuilder.build do |xml|
      xml.html do 
        xml.head do
          xml.meta name: "viewport", content: \
              "width=device-width, initial-scale=1"
          xml.style "\nbody {font-family: Arial;}\n\n"
        end
        xml.body build_elements
      end
    end
    
  end

  def build_js(doc)


ajax=<<EOF
function ajaxRequest(url, cFunction) {
  var xhttp;
  xhttp = new XMLHttpRequest();
  xhttp.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      cFunction(this);
    }
  };
  xhttp.open("GET", url, true);
  xhttp.send();
}
EOF

    funcs_defined = @requests.map.with_index do |x,i|
      
      puts ('x: ' + x.inspect).debug if @debug
      server, raw_type, target, target_eval = x
      
      if raw_type.first == :trigger then
        modify_trigger_function(raw_type.last, i, server, doc)
      end
      
      add_element_function(raw_type.last, i, server, target, target_eval)
      
    end
    
    s = "\n\n" + ajax + "\n\n" + funcs_defined.join
    "\n  <script>\n%s\n  </script>\n" % s  

  end
  
  def modify_element(element, doc, i)
    
    selector = if element[:id] then
      '#' + element[:id]
    elsif element[:type]
      "*[@type='%s']" % element[:type]
    end
    
    if @debug then
      puts ("selector: %s" % selector.inspect).debug
      puts 'doc: ' + doc.xml(pretty: true).inspect
    end
    
    e = doc.at_css(selector)
    puts ('e: ' + e.inspect).debug if @debug
    return unless e
    puts ('e: ' + e.inspect).debug if @debug
    
    func = 'ajaxCall' + (i+1).to_s
    event = e.attributes[:type] == 'button' ? func + '()' : func + '(this)'
    
    puts ('element: ' + element.inspect).debug if @debug
    
    key = if element[:event] then
    
      if element[:event].to_sym == :on_enter then
        event = func + '(event.keyCode, this)'
        :onkeyup
      else
        element[:event].to_sym
      end
      
    else
      e.attributes[:type] == 'button' ? :onclick : :onkeyup
    end
    
    e.attributes[key] = event    
  end
  
  def modify_trigger(element, doc, i)
  end
  
  def modify_trigger_function(trigger, i, server, doc)
    
    doc.root.xpath('//script').each do |script|
      puts 'script: ' + script.inspect
      s = script.text.to_s
      
      script.text = s.sub(/#{trigger} = function\(\) {[^}]+/) {|x|
        a = x.lines
        indent = a[1][/\s+/]
        a[0..-2].join + indent + "ajaxCall#{i+1}(event.results[0][0]." + 
                                                       "transcript);\n" + a[-1]
      }
      
    end
    
  end
  
  # find the ajax requests
  #
  def scan_requests(html)
    

    a = html.scan(/\$\[([^\]]+)?\]\(([^\)]+)/)

    a.each do |var, url|

      #== fetch the trigger element details

      tag = html[/<[^<]+\$\[([^\]]+)?\]\(#{url}[^\>]+>/]
      element_name  = tag[/(?<=<)\w+/]
      event = tag[/(\w+)=["']\$\[([^\]]+)?\]\(#{url}/,1]

      # is there an id?
      id = tag[/(?<=id=["'])[^"']+/]

      h2 = if id then
        {id: id}
      else
        {type: element_name.to_sym }
      end

      element = h2.merge(event: event)

      if var.nil? then
        
        add_request(server: url, element: element, target_eval: true)
        next
        
      end

      #== fetch the target element details

      tag2 = html[/<[^<]+>\$#{var}</]
      # is there an id?
      target_id = tag2[/(?<=id=["'])[^"']+/]

      inner_html = tag2 =~ />\$#{var}</

      property = if inner_html then
      
        html.sub!(/>\$#{var}</,'>&nbsp;<')
        :innerHTML
        
      end

      target_element = {id: target_id, property: property}

      add_request(server: url, element: element, 
                  target_element: target_element)
      
    end
    
  end

end
