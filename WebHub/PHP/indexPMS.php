<!DOCTYPE HTML>
<html>

<head>
    <title> PMS Website v1.0 </title>
    <!-- HTML5 and mobile devices -->
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <!-- styling formats in order of ascending importance (i.e. custom css trumps bootstrap -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap-theme.min.css">
	<link type="text/css" rel="stylesheet" href="mainPMS.css">
    <!-- jQuery library -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
    <!-- Latest compiled JavaScript -->
    <script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min.js"></script>
    <!-- [if IE]> -->
    <script src="https://cdn.jsdelivr.net/html5shiv/3.7.2/html5shiv.min.js"></script>
    <script src="https://cdn.jsdelivr.net/respond/1.4.2/respond.min.js"></script>
</head>

<body>
    <div class="nav">
        <div class="containter">
            <ul class="pull-left">
                <li> <a href="#"> BioFire Home </a> </li>
                <li> <a href="#"> Quality Web </a> </li>
                <li> <a href="#"> Production Web</a> </li>
            </ul>
            <ul class="pull-right">
                <li> <a href="#"> Contact Us </a> </li>
            </ul>
        </div>
    </div>
    <div class="jumbotron">
        <div class="container">
            <h1> Post Market Surveillance </h1>
            <p> Data monitoring to identify and investigate trends related to released FilmArray products.</p>
        </div>
    </div>
    <div class="mainlinks">
        <div class="container">
            <h2> Find your data </h2>
            <p> Explore the reports with metrics generated using BioFire Diagnostics internal databases.</p>
            <div class="row">
                <div class="col-md-4">
                    <div class="thumbnail">
                        <h3> <img class="thumb" src="images/thumbNCR.png"/> </h3>
                        <p> <a href="#"> NCR Tracker </a> </p>
                    </div>
                    <div class="thumbnail">
                        <h3> <img class="thumb" src='images/thumbRMA.png'/> </h3>
                        <p> <a href="#"> RMA Tracker </a> </p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="thumbnail">
                        <h3> <img class="thumb" src="images/thumbComplaint.png"/> </h3>
                        <p> <a href="#"> Complaint Tracker </a> </p>
                    </div>
                    <div class="thumbnail">
                        <h3> <img class="thumb" src="images/thumbCI.png"/> </h3>
                        <p> <a href="#"> CI Tracker </a> </p>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="thumbnail">
                        <h3> <img class="thumb" src="images/thumbFloor.png"/> </h3>
                        <p> <a href="#"> Floor Failures </a> </p>
                    </div>
                    <div class="thumbnail">
                        <h3> <img class="thumb" src="images/thumbOther.png"/> </h3>
                        <p> <a href="#"> Other Metrics </a> </p>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="footer">
        <ul class="pull-right">
            <li> <img class="logo" src='http://itweb.isaos/sales/images/Logos/BFD_FullColor.jpg'/> </li>
        </ul>
    </div>
    
    <!--<?php $myNum = 3; switch($myNum) { case 3: echo "My number is 3."; break; default: echo "My number is not 3"; }; ?> -->
    
</body>

</html>