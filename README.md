# firebase_rtd_paginate

firebase_rtd_paginate is a flutter library for dealing with pagination in Firebase Realtime Database.

It supports sorting of data based on a child attribute, for example, number of likes, etc. It also supports de-duplication of data if the database is dynamic and evolving.

Currently, refresh and load more functionalities are supported.

## Installation

In the ```dependencies:``` section of your ```pubspec.yaml```, add the following line:

```python
firebase_rtd_paginate: 1.0.0
```


## Usage

```dart
import 'package:firebase_rtd_paginate/firebase_rtd_paginate.dart';
```
You do not need to initialize the class.

```dart
// create the listview or gridview here
// remember to specify the item model type which will be created when fetched from the database
FirebaseRTDPaginate<Channel>(
      query: exploreManager.database.databaseInstance.reference().child("ChannelsMetadata"),
      padding: EdgeInsets.only(bottom: 50),
      itemWidgetBuilder: (context, channel, index) {
        return ChannelListTile(
          key: Key('channel-${channel.key}'),
          channel: channel,
          onSelectChannel: (Channel channel) {
            ChannelPage.show(context, channel: channel);
          },
        );
      },
      itemsPerPage: 15,
      modelBuilder: (item, key) {
        return Channel.fromMap(item, key);
      },
      comparatorItem: (left, right){
        return (right.subscriberCount).compareTo(left.subscriberCount);
      },
      attribute: "subscriberCount",
      itemBuilderType: PaginateBuilderType.listView,
)
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](https://choosealicense.com/licenses/mit/)
