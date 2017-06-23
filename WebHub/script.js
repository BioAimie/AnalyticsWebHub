/*jslint browser: true*/
/*global $, jQuery, alert*/

$(document).ready(function () {
    'use strict';
    $('.brighten').mouseenter(function () {
        $(this).animate({
            opacity: '1'
        });
    });
    $('.brighten').mouseleave(function () {
        $(this).animate({
            opacity: '0.5'
        });
    });
    $('#dropdown').click(function () {
        $('.panel').slideToggle('slow');
    });
    $('.panel').mouseleave(function () {
        $(this).slideToggle('fast');
    }); 
    $('.plus').click(function () {
        if (this.innerHTML === '+') {
            this.innerHTML = '-';
        } 
        else {
            this.innerHTML = '+';
        }
    });
    $('#menuButton').click(function () {
        $("#sideBar").toggle( "slide" );
        if (this.innerHTML === '-') {
            $('.image-slider')[0].slick.refresh();
            $('.slick-prev').css('left', '300px');
        } 
        else {
            $('.image-slider')[0].slick.refresh();
        }
    });
    $('.image-slider').slick({
        arrows: true,
        autoplay: false,
        dots: true
    });
    $('.image-slider2').slick({
        arrows: true,
        autoplay: false,
        dots: false
    });
});




var net = require('net');

var portInUse = function(port, callback) {
    var server = net.createServer(function(socket) {
	socket.write('Echo server\r\n');
	socket.pipe(socket);
    });

    server.listen(port, '172.26.28.96');
    server.on('error', function (e) {
	callback(true);
    });
    server.on('listening', function (e) {
	server.close();
	callback(false);
    });
};

portInUse(4027, function(returnValue) {
    document.body.innerHTML += "some message ";
});