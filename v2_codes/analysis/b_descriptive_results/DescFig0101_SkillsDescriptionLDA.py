#! python3

"""
This python script file conducts 3-topic LDA to a set of skills text data.

Input:
    SkillsInput.dta <== raw data


RA: WWZ
Time: 2025-03-19
"""

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 0. configuration
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-0-1. necessary packages
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

import os
import sys
from pathlib import Path
import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.decomposition import LatentDirichletAllocation
from wordcloud import WordCloud
import matplotlib.pyplot as plt

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-0-2. paths specifications
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?

paths_v2_codes = Path(__file__).resolve().parents[2]
sys.path.append(str(paths_v2_codes))

import v2_main as setup

# !! input dataset
path_skills = setup.dir_data_raw_mne / "SkillsInput.dta"
# !! output dataset
path_output_data = setup.dir_data_temp / "DescFig0101_SkillsAfterLDA.dta"
# !! output figures
path_results = setup.dir_out_descrip

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 1. transformation of the dataset (turn ind-skill level to ind level)
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

data = pd.read_stata(path_skills)

skills_ind = data[["IDlse", "Skills"]].copy()
skills_ind = skills_ind.dropna()
skills_ind.dtypes
skills_ind["IDlse"] = skills_ind["IDlse"].astype(np.int64)
skills_ind["Skills"] = skills_ind["Skills"].astype("string")
skills_ind

skills_combined = skills_ind.groupby("IDlse")["Skills"].agg(lambda x: ", ".join(x)).reset_index()

# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# ?? step 2. LDA analysis on the Skills variable
# ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

# Preprocess the skills data
vectorizer = CountVectorizer()
skills_matrix = vectorizer.fit_transform(skills_combined["Skills"])

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-1. Fit 3-topic LDA model
# -?        and get topic distributions for each individual
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?


#!! A function to fit LDA model and get topic distributions
def fit_lda_and_get_topics(n_topics, skills_matrix):
    lda_model = LatentDirichletAllocation(n_components=n_topics, random_state=42)
    lda_model.fit(skills_matrix)
    topic_distributions = lda_model.transform(skills_matrix)

    for i in range(n_topics):
        skills_combined[f"Topic{i+1}_{n_topics}"] = topic_distributions[:, i]

    return lda_model


#!! Fit the LDA model with 3 topics
lda_3_topics = fit_lda_and_get_topics(3, skills_matrix)

#!! Fit the LDA model with 3 topics
skills_combined[
    [
        "IDlse",
        "Topic1_3",
        "Topic2_3",
        "Topic3_3",
    ]
].to_stata(path_output_data)

# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?
# -? s-2-2. Describe the resulting topic
# -?        (word distribution) using word cloud
# -?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?#-?


# !! A function to extract the top words for each topic
def get_top_words(model, feature_names, n_top_words):
    top_words = {}
    for topic_idx, topic in enumerate(model.components_):
        top_words_for_topic = {
            feature_names[i]: topic[i] for i in topic.argsort()[: -n_top_words - 1 : -1]
        }
        top_words[f"Topic {topic_idx + 1}"] = top_words_for_topic
    return top_words


# !! A function to generate word clouds for topics
def generate_word_clouds(top_words, filepath, model_type):
    for topic, words_probs in top_words.items():
        if topic == "Topic 1":
            wordcloud = WordCloud(
                width=550,
                height=400,
                background_color="white",
                color_func=lambda *args, **kwargs: (145, 179, 215),
                random_state=2000,
            ).generate_from_frequencies(words_probs)
        if topic == "Topic 2":
            wordcloud = WordCloud(
                width=550,
                height=400,
                background_color="white",
                color_func=lambda *args, **kwargs: (255, 153, 51),
                random_state=2000,
            ).generate_from_frequencies(words_probs)
        if topic == "Topic 3":
            wordcloud = WordCloud(
                width=550,
                height=400,
                background_color="white",
                color_func=lambda *args, **kwargs: (255, 51, 51),
                random_state=2000,
            ).generate_from_frequencies(words_probs)
        plt.figure()
        plt.imshow(wordcloud, interpolation="bilinear")
        plt.axis("off")
        final_file_path = os.path.join(filepath, f"{model_type}_{topic}.png")
        plt.savefig(final_file_path)
        plt.show()
        plt.close()


# !! Get top words for 3-topic model
feature_names = vectorizer.get_feature_names_out()
top_words_3_topics_1000 = get_top_words(lda_3_topics, feature_names, 1000)

# !! Generate word clouds for 3-topic model
generate_word_clouds(top_words_3_topics_1000, path_results, "LDA3_1000Words")

# !! word clouds with 50 words version
# top_words_3_topics_50 = get_top_words(lda_3_topics, feature_names, 50)
# generate_word_clouds(top_words_3_topics_50, path_results, "LDA3_50Words")

# # ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??
# # ?? step 3. Test 2- and 5-Topic LDA analysis
# # ??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??#??

# #!! Fit the LDA model with 2 and 5 topics
# lda_2_topics = fit_lda_and_get_topics(2, skills_matrix)
# lda_5_topics = fit_lda_and_get_topics(5, skills_matrix)

# # !! Get top words for 2- and 5-topic model
# top_words_2_topics_1000 = get_top_words(lda_2_topics, feature_names, 1000)
# top_words_5_topics_1000 = get_top_words(lda_5_topics, feature_names, 1000)

# # !! Generate word clouds for 2- and 5-topic model
# generate_word_clouds(
#     top_words_2_topics_1000, path_results, "LDA2_1000Words"
# )
# generate_word_clouds(
#     top_words_5_topics_1000, path_results, "LDA5_1000Words"
# )
