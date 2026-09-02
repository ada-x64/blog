#import "_template.typ": *
#show: post.with(
  title: "On the ethics of open source in the age of AI",
  tags: (),
  draft: true,
)

thesis: Common arguments about no longer supporting open source code or migrating to websites such as codeburg or tangled are often conflated. Some people would say that supporting open code is no longer an ethical decision because that open code will be scraped and used to train AI models without consent. It's a valid concern. However I would like to argue that the benefits of an agentic workflow far outweigh the detriments of sharing your code in public and allowing it to be scraped.

Those who advocate for a move away from GitHub do so on the grounds of a lack of consent regarding scraping and selling of what might be perceived as personal intellectual property. In many cases the scraping was done without consideration for the licensing on which the entire open source ecosystem is built. This represents a genuine concern - if the license is not respected, then it serves no purpose. A large concern with these groups is that the licenses are being ignored by the very companies who require their usage. Licenses were meant to be a safeguard against large scale corporations such as Microsoft stealing code without any credit. However, the licensing model seems to have run its course. By publishing your code to GitHub you are implicitly agreeing to have it scraped and used to train the GitHub copilot agent. There is no such implicit agreement on alternate get hosts such as codeburg, gitlab, or tangled.

I don't want to condone the underhanded tactics that Microsoft and the legal team at GitHub have used to manipulate their users into helping them create an immensely profitable product without their knowledge. However, I do think it is wrong headed to argue that open source code should not be used to train models. There are ethically sourced large language models such as star coder which rely only on open source code which has consensually been taken for training data. I think that in the pursuit of better agentic tools and more ethical agentic tools we ought to be submitting our code as training data for large language models.
