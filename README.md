# Introducing the jsajax_wizard gem

## Usage

    require 'jsajax_wizard'

    jaw = JsAjaxWizard.new
    jaw.add_request server: 'hello', element: {type: 'button', event: 'onclick'}, target_element: {id: 'demo', property: :innerHTML}

    File.write '/tmp/demo.html', jaw.to_html

The above example generates an AJAX enabled web page which returns text from a server whenever the button is pressed. This gem is intended to make it easier to build a web page which uses AJAX.

Note: The web page must be hosted on the same web server as the server usef for the AJAX http request.

## Resources

* jsajax_wizard https://rubygems.org/gems/jsajax_wizard

jsajax_wizard gem wizard builder ajax
