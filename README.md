# Coral Framework

## Simple 2d game development platform for the Nim programming language (Warning) This framework is under heavy development

<form action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="hosted_button_id" value="H5PC5ZLB4GMPE">
<input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">
<img alt="" border="0" src="https://www.paypalobjects.com/en_US/i/scr/pixel.gif" width="1" height="1">
</form>

## Getting Started

```nim
import
    Coral/game,
    Coral/graphics,
    Coral/renderer

Coral.render = proc()=
    Coral.r2d.drawRect(100, 100, 100, 100, 45.0, Red)

Coral.createGame(800, 600, "My Coral Game", config())
    .run()
```