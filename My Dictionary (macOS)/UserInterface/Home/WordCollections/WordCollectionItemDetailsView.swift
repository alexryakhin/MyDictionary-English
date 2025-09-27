//
//  WordCollectionItemDetailsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 9/12/25.
//

import SwiftUI

struct WordCollectionItemDetailsView: View {
    let word: WordCollectionItem
    let collection: WordCollection

    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(alignment: .leading, spacing: 20) {

                // Word header
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.text)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let phonetics = word.phonetics {
                        Text(phonetics)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    TagView(text: word.partOfSpeech.displayName, color: .blue)
                }

                // Definition
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.Words.meaning)
                        .font(.headline)
                    Text(word.definition)
                        .font(.body)
                }

                // Examples
                if !word.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.Words.examples)
                            .font(.headline)

                        ForEach(word.examples, id: \.self) { example in
                            Text("• \(example)")
                                .font(.body)
                                .padding(.leading, 8)
                        }
                    }
                }

                // Collection info
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.WordCollections.fromCollection)
                        .font(.headline)
                    Text(collection.title)
                        .font(.body)
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        } navigationBar: {
            NavigationBarView(
                title: Loc.WordCollections.details,
                mode: .inline
            )
        }
        .groupedBackground()
        .frame(width: 400, height: 500)
    }
}
