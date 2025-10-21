import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';

class BigCard extends StatelessWidget {
    const BigCard({
        super.key,
        required this.pair,
    });

    final WordPair pair;

    @override
    Widget build(BuildContext context) {
        final style = Theme.of(context).textTheme.displayMedium!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
        );

        return Card(
            color: Theme.of(context).colorScheme.secondary,
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(pair.asLowerCase, style: style),
            ),
        );
    }
}