import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:lunasea/logic/automation/lidarr.dart';
import 'package:lunasea/pages/lidarr/subpages/details/album.dart';
import 'package:lunasea/system/constants.dart';
import 'package:lunasea/system/ui.dart';

class Missing extends StatelessWidget {
    final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;

    Missing({
        Key key,
        @required this.refreshIndicatorKey,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return _MissingWidget(refreshIndicatorKey: refreshIndicatorKey);
    }
}

class _MissingWidget extends StatefulWidget {
    final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;

    _MissingWidget({
        Key key,
        @required this.refreshIndicatorKey,
    }) : super(key: key);

    @override
    State<StatefulWidget> createState() {
        return _MissingState(refreshIndicatorKey: refreshIndicatorKey);
    }
}

class _MissingState extends State<StatefulWidget> {
    final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    List<LidarrMissingEntry> _missingEntries = [];
    bool _loading = true;

    _MissingState({
        Key key,
        @required this.refreshIndicatorKey,
    });

    @override
    void initState() {
        super.initState();
        Future.delayed(Duration(milliseconds: 200)).then((_) {
            if(mounted) {
                refreshIndicatorKey?.currentState?.show();
            }
        });
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            body: RefreshIndicator(
                key: refreshIndicatorKey,
                backgroundColor: Color(Constants.SECONDARY_COLOR),
                onRefresh: _handleRefresh,
                child: _loading ?
                    Notifications.centeredMessage('Loading...') :
                    _missingEntries == null ?
                        Notifications.centeredMessage('Connection Error', showBtn: true, btnMessage: 'Refresh', onTapHandler: () {refreshIndicatorKey?.currentState?.show();}) :
                        _missingEntries.length == 0 ?
                            Notifications.centeredMessage('No Missing Albums', showBtn: true, btnMessage: 'Refresh', onTapHandler: () {refreshIndicatorKey?.currentState?.show();}) :
                            _buildList(),
            ),
        );
    }

    Future<void> _handleRefresh() async {
        if(mounted) {
            setState(() {
                _loading = true;
                _missingEntries = [];
            });
        }
        _missingEntries = await LidarrAPI.getMissing();
        if(mounted) {
            setState(() {
                _loading = false;
            });
        }
    }

    Widget _buildList() {
        return Scrollbar(
            child: ListView.builder(
                itemCount: _missingEntries.length,
                itemBuilder: (context, index) {
                    return _buildEntry(_missingEntries[index]);
                },
                padding: Elements.getListViewPadding(),
                physics: AlwaysScrollableScrollPhysics(),
            ),
        );
    }

    Widget _buildEntry(LidarrMissingEntry entry) {
        return Card(
            child: Container(
                child: ListTile(
                    title: Elements.getTitle(entry.artistTitle),
                    subtitle: RichText(
                        text: TextSpan(
                            style: TextStyle(
                                color: Colors.white70,
                                letterSpacing: Constants.LETTER_SPACING,
                            ),
                            children: <TextSpan>[
                                TextSpan(
                                    text: entry.title,
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                    ),
                                ),
                                TextSpan(
                                    text: '\nReleased ${entry.releaseDateString}',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                    ),
                                ),
                            ],
                        ),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 2,
                    ),
                    trailing: IconButton(
                        icon: Elements.getIcon(Icons.search),
                        tooltip: 'Search',
                        onPressed: () async {
                            if(await LidarrAPI.searchAlbums([entry.albumID])) {
                                Notifications.showSnackBar(_scaffoldKey, 'Searching for ${entry.title}...');
                            } else {
                                Notifications.showSnackBar(_scaffoldKey, 'Failed to search for ${entry.title}');
                            }
                        },
                    ),
                    contentPadding: Elements.getContentPadding(),
                    onTap: () async {
                        _enterAlbum(entry);
                    },
                ),
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AdvancedNetworkImage(
                            entry.bannerURI(),
                            useDiskCache: true,
                            loadFailedCallback: () {},
                            fallbackAssetImage: 'assets/images/secondary_color.png',
                            retryLimit: 1,
                        ),
                        colorFilter: new ColorFilter.mode(Color(Constants.SECONDARY_COLOR).withOpacity(0.20), BlendMode.dstATop),
                        fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                ),
            ),
            margin: Elements.getCardMargin(),
            elevation: 4.0,
        );
    }

    Future<void> _enterAlbum(LidarrMissingEntry entry) async {
        final result = await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => LidarrAlbumDetails(
                    title: entry.title,
                    albumID: entry.albumID,
                    monitored: entry.monitored,
                ),
            ),
        );
        //Handle the result
        switch(result) {
        }
    }
}
