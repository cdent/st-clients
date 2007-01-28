// From https://developer.apple.com/documentation/AppleApplications/Conceptual/Dashboard_Tutorial/Preferences/chapter_5_section_3.html

function showBack() {
    var front = document.getElementById("front");
    var back = document.getElementById("back");
    if (window.widget)
        widget.prepareForTransition("ToBack");
    front.style.display="none";
    back.style.display="block";
    backView.display();
    if (window.widget)
        setTimeout ('widget.performTransition();', 0);  
}

function hideBack() {
    var front = document.getElementById("front");
    var back = document.getElementById("back");
    if (window.widget)
        widget.prepareForTransition("ToFront");
    back.style.display="none";
    front.style.display="block";
    if (window.widget)
        setTimeout ('widget.performTransition();', 0);
}

var flipShown = false;
var animation = {duration:0, starttime:0, to:1.0, now:0.0, from:0.0, firstElement:null, timer:null};
function mousemove (event)
{
    if (!flipShown)
    {
        if (animation.timer != null)
        {
            clearInterval (animation.timer);
            animation.timer  = null;
        }
        var starttime = (new Date).getTime() - 13;
        animation.duration = 500;
        animation.starttime = starttime;
        animation.firstElement = document.getElementById ('flip');
        animation.timer = setInterval ("animate();", 13);
        animation.from = animation.now;
        animation.to = 1.0;
        animate();
        flipShown = true;
    }
}
function mouseexit (event)
{
    if (flipShown)
    {
        // fade in the info button
        if (animation.timer != null)
        {
            clearInterval (animation.timer);
            animation.timer  = null;
        }
        var starttime = (new Date).getTime() - 13;
        animation.duration = 500;
        animation.starttime = starttime;
        animation.firstElement = document.getElementById ('flip');
        animation.timer = setInterval ("animate();", 13);
        animation.from = animation.now;
        animation.to = 0.0;
        animate();
        flipShown = false;
    }
}
function animate()
{
    var T;
    var ease;
    var time = (new Date).getTime();
    T = limit_3(time-animation.starttime, 0, animation.duration);
    if (T >= animation.duration)
    {
        clearInterval (animation.timer);
        animation.timer = null;
        animation.now = animation.to;
    }
    else
    {
        ease = 0.5 - (0.5 * Math.cos(Math.PI * T / animation.duration));
        animation.now = computeNextFloat (animation.from, animation.to, ease);
    }
    animation.firstElement.style.opacity = animation.now;
}
function limit_3 (a, b, c)
{
    return a < b ? b : (a > c ? c : a);
}
function computeNextFloat (from, to, ease)
{
    return from + (to - from) * ease;
}
function enterflip(event)
{
    document.getElementById('fliprollie').style.display = 'block';
}
function exitflip(event)
{
    document.getElementById('fliprollie').style.display = 'none';
}
