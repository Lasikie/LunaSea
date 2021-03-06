import 'package:flutter/material.dart';
import 'package:lunasea/logic/automation/lidarr.dart';
import 'package:lunasea/system/ui.dart';

class LidarrEditArtist extends StatelessWidget {
    final LidarrCatalogueEntry entry;

    LidarrEditArtist({
        Key key,
        @required this.entry
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return _LidarrEditArtistWidget(entry: entry);
    }
}

class _LidarrEditArtistWidget extends StatefulWidget {
    final LidarrCatalogueEntry entry;

    _LidarrEditArtistWidget({
        Key key,
        @required this.entry
    }) : super(key: key);

    @override
    State<StatefulWidget> createState() {
        return _LidarrEditArtistState(entry: entry);
    }
}

class _LidarrEditArtistState extends State<StatefulWidget> {
    final LidarrCatalogueEntry entry;
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    bool _loading = true;

    List<LidarrQualityProfile> _qualityProfiles = [];
    List<LidarrMetadataProfile> _metadataProfiles = [];
    LidarrQualityProfile _qualityProfile;
    LidarrMetadataProfile _metadataProfile;
    String _path;
    bool _monitored;
    bool _albumFolders;

    _LidarrEditArtistState({
        Key key,
        @required this.entry,
    });

    @override
    void initState() {
        super.initState();
        _fetchData();
    }

    Future<void> _fetchData() async {
        if(mounted) {
            setState(() {
                _loading = true;
            });
        }
        final profiles = await LidarrAPI.getQualityProfiles();
        _qualityProfiles = profiles?.values?.toList();
        if(_qualityProfiles != null && _qualityProfiles.length != 0) {
            for(var profile in _qualityProfiles) {
                if(profile.id == entry.qualityProfile) {
                    _qualityProfile = profile;
                }
            }
        }
        final metadatas = await LidarrAPI.getMetadataProfiles();
        _metadataProfiles = metadatas?.values?.toList();
        if(_metadataProfiles != null && _metadataProfiles.length != 0) {
            for(var profile in _metadataProfiles) {
                if(profile.id == entry.metadataProfile) {
                    _metadataProfile = profile;
                }
            }
        }
        _path = entry.path;
        _monitored = entry.monitored;
        _albumFolders = entry.albumFolders;
        if(mounted) {
            setState(() {
                _loading = false;
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            appBar: Navigation.getAppBar(entry.title, context),
            body: _loading ?
                Notifications.centeredMessage('Loading...') : 
                checkValues() ? 
                    _buildList() :
                    Notifications.centeredMessage('Connection Error', showBtn: true, btnMessage: 'Refresh', onTapHandler: () async {
                        _fetchData();
                    }),
            floatingActionButton: _loading ?
                null :
                checkValues() ?
                    _buildFloatingActionButton() :
                    null,
        );
    }

    bool checkValues() {
        if(
            _qualityProfile != null &&
            _qualityProfiles != null &&
            _metadataProfile != null &&
            _metadataProfiles != null
        ) {
            return true;
        }
        return false;
    }

    Widget _buildFloatingActionButton() {
        return FloatingActionButton(
            heroTag: null,
            tooltip: 'Save Changes',
            child: Elements.getIcon(Icons.save),
            onPressed: () async {
                if(await LidarrAPI.editArtist(entry.artistID, _qualityProfile, _metadataProfile, _path, _monitored, _albumFolders)) {
                    entry.qualityProfile = _qualityProfile.id;
                    entry.quality = _qualityProfile.name;
                    entry.metadataProfile = _metadataProfile.id;
                    entry.metadata = _metadataProfile.name;
                    entry.path = _path;
                    entry.monitored = _monitored;
                    entry.albumFolders = _albumFolders;
                    Navigator.of(context).pop(['updated_artist', entry]);
                } else {
                    Notifications.showSnackBar(_scaffoldKey, 'Failed to update ${entry.title}');
                }
            },
        );
    }

    Widget _buildList() {
        return Scrollbar(
            child: ListView(
                children: <Widget>[
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Monitored'),
                            subtitle: Elements.getSubtitle('Monitor artist for new releases'),
                            trailing: Switch(
                                value: _monitored,
                                onChanged: (value) {
                                    setState(() {
                                        _monitored = value;
                                    });
                                },
                            ),
                        ),
                        elevation: 4.0,
                        margin: Elements.getCardMargin(),
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Use Album Folders'),
                            subtitle: Elements.getSubtitle('Sort tracks into album folders'),
                            trailing: Switch(
                                value: _albumFolders,
                                onChanged: (value) {
                                    setState(() {
                                        _albumFolders = value;
                                    });
                                },
                            ),
                        ),
                        elevation: 4.0,
                        margin: Elements.getCardMargin(),
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Artist Path'),
                            subtitle: Elements.getSubtitle(_path, preventOverflow: true),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.arrow_forward_ios),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await SystemDialogs.showEditTextPrompt(context, 'Artist Path', prefill: _path);
                                if(_values[0]) {
                                    setState(() {
                                        _path = _values[1];
                                    });
                                }
                            }
                        ),
                        elevation: 4.0,
                        margin: Elements.getCardMargin(),
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Quality Profile'),
                            subtitle: Elements.getSubtitle(_qualityProfile.name, preventOverflow: true),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.arrow_forward_ios),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await LidarrDialogs.showEditQualityProfilePrompt(context, _qualityProfiles);
                                if(_values[0]) {
                                    setState(() {
                                        _qualityProfile = _values[1];
                                    });
                                }
                            },
                        ),
                        elevation: 4.0,
                        margin: Elements.getCardMargin(),
                    ),
                    Card(
                        child: ListTile(
                            title: Elements.getTitle('Metadata Profile'),
                            subtitle: Elements.getSubtitle(_metadataProfile.name, preventOverflow: true),
                            trailing: IconButton(
                                icon: Elements.getIcon(Icons.arrow_forward_ios),
                                onPressed: null,
                            ),
                            onTap: () async {
                                List<dynamic> _values = await LidarrDialogs.showEditMetadataProfilePrompt(context, _metadataProfiles);
                                if(_values[0]) {
                                    setState(() {
                                        _metadataProfile = _values[1];
                                    });
                                }
                            },
                        ),
                        elevation: 4.0,
                        margin: Elements.getCardMargin(),
                    ),
                ],
                padding: Elements.getListViewPadding(),
            ),
        );
    }
}