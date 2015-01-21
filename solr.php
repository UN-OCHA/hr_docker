<?php
$server = search_api_server_load('hr_solr');
$server->options['host'] = 'solr.hrinfo.vm';
$server->options['port'] = '8984';
$server->options['path'] = '/solr/core0';
$server->save();
