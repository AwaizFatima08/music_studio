#!/usr/bin/env python3
"""Insert the Tiny Tunes Studio blocks into index.html, privacy.html and terms.html.

Usage: add_tinytunes.py <dir-with-the-three-pages>
Works on the local homilabs_tools site/ copy and on copies downloaded from the live site, so only
Tiny Tunes Studio is added to the live pages. Running it twice changes nothing.
Also copy img/tinytunes/icon.png (from /mnt/storage/projects/Tools/music_studio/web/) to <site>/img/tinytunes/icon.png.
"""
import re
import sys
from pathlib import Path

DATE = '17 November 2026'

CARD = '''    <!-- ===== TOOL: Tiny Tunes Studio ===== -->
    <article class="tool" id="tinytunes" style="--tool:#7c4dff">
      <div class="tool-head">
        <img src="img/tinytunes/icon.png" alt="Tiny Tunes Studio app icon" width="64" height="64">
        <div>
          <h3>Tiny Tunes Studio</h3>
          <p class="tagline">A music studio for little ones: play, make beats and sing karaoke</p>
        </div>
      </div>
      <p>Nine colourful rooms full of toy instruments, sing-along songs and a karaoke stage with silly voices.</p>
      <ul>
        <li>Piano, xylophone, magic flute, guitar, drums and silly sounds, with many fingers at once</li>
        <li>Beat Maker with ready-made grooves, and play-along songs where a child can't press a wrong key</li>
        <li>Karaoke with bouncing lyrics; hear yourself back as a chipmunk, giant or robot (the voice is never saved)</li>
      </ul>
      <div class="chips">
        <span class="chip">Android</span>
        <span class="chip">Kids</span>
        <span class="chip">No login</span>
      </div>
      <div class="tool-foot">
        <span class="status soon">Coming soon to Google Play</span>
        <span class="tool-links"><a href="privacy.html#tinytunes">Privacy</a><a href="terms.html#tinytunes">Terms</a></span>
      </div>
    </article>
    <!-- ===== END TOOL: Tiny Tunes Studio ===== -->

'''

TOC = '      <li><a href="#tinytunes">Tiny Tunes Studio</a></li>\n'

PRIVACY = f'''  <!-- ===== APP: Tiny Tunes Studio ===== -->
  <section id="tinytunes" class="app-block">
    <h2><img src="img/tinytunes/icon.png" alt="" width="36" height="36">Tiny Tunes Studio</h2>
    <p class="meta">Android · package com.homilabs.tinytunes · Section updated {DATE} (version 1.0.0)</p>

    <p><strong>Tiny Tunes Studio is made for young children and collects no personal information.</strong> There is no
      account, no sign-in, no chat and no analytics, and the app never asks a child to type anything. All sounds and
      music are made inside the app. Tiny Tunes Studio is free and shows one small ad from <strong>Google AdMob</strong>,
      only on the grown-ups settings screen, which a child can reach only by holding the gear button and answering a sum.
      No ads ever appear on the play screens.</p>

    <table>
      <tr class="head"><th>What Tiny Tunes Studio uses</th><th>Why</th><th>Leaves your phone?</th></tr>
      <tr><td>Microphone (Karaoke only, while a song is playing)</td><td>So the child can hear their singing played back
        over the music, as themselves or with a silly voice. The voice is kept only in the phone's memory while the
        karaoke screen is open. It is <strong>never saved to storage, never uploaded and never shared</strong>, and it is
        gone as soon as the child leaves the screen. Grown-ups can switch the microphone off (sing-along only).</td>
        <td data-label="Leaves your phone: ">No</td></tr>
      <tr><td>Settings: volume and loudest-volume limit, key labels, sparkles, karaoke microphone and keep-screen-on
        choices</td><td>So the app opens the way you left it. Saved on your phone only; removed when you clear the app's
        data or uninstall it.</td><td data-label="Leaves your phone: ">No</td></tr>
      <tr><td>Advertising (Google AdMob), grown-ups screen only</td><td>To show one banner. Every ad request is marked as
        coming from an app for children, so Google serves only <strong>non-personalised, family-safe (rated G)</strong>
        ads and does not build an advertising profile. The app does not use or send the device's advertising ID.
        Google may still receive the IP address, basic device and app information and ad interactions to deliver and
        measure the ad and to prevent fraud.</td><td data-label="Leaves your phone: ">Yes, to Google, only when the
        grown-ups screen is open</td></tr>
    </table>

    <h3>Permissions</h3>
    <ul>
      <li><strong>Record audio</strong> (RECORD_AUDIO): asked for the first time a child presses <em>Sing</em> in
        Karaoke, used only while a karaoke song plays. If it is refused or switched off, karaoke still works as a
        sing-along.</li>
      <li>Internet and network state, for the ad on the grown-ups screen.</li>
    </ul>
    <p>Tiny Tunes Studio does not request location, contacts, camera, storage or phone access, and it does not use the
      advertising ID.</p>

    <h3>Children</h3>
    <p>Tiny Tunes Studio is designed for children aged about 2 to 8 and follows Google Play's Families policy. We do not
      knowingly collect personal information from children. Links to this policy and to the terms are inside the
      grown-ups area, behind the parent gate.</p>

    <h3>Your choices</h3>
    <ul>
      <li>Switch off <em>Karaoke: record my child's voice</em> in the grown-ups area, or deny the microphone permission
        in Android's settings.</li>
      <li>If you are in the European Economic Area, the UK or Switzerland, Google's consent form may appear; you can
        change your choice under <em>Grown-ups → Ad privacy options</em>.</li>
      <li>Clearing the app's data or uninstalling it removes all settings.</li>
    </ul>
    <p>Google's use of this data is covered by its own policy:
      <a href="https://policies.google.com/technologies/partner-sites">How Google uses information from sites or apps
      that use its services</a>.</p>
  </section>
  <!-- ===== END APP: Tiny Tunes Studio ===== -->

'''

TERMS = f'''  <!-- ===== APP: Tiny Tunes Studio ===== -->
  <section id="tinytunes" class="app-block">
    <h2><img src="img/tinytunes/icon.png" alt="" width="36" height="36">Tiny Tunes Studio</h2>
    <p class="meta">Additional terms for Tiny Tunes Studio · updated {DATE}</p>

    <h3>Grown-ups in charge</h3>
    <p>Tiny Tunes Studio is a free music toy for young children to use with an adult nearby. Keep play sessions short,
      take breaks from the screen, and set a comfortable "Loudest volume allowed" in the grown-ups area. For small ears,
      keep the volume low, especially with headphones.</p>

    <h3>Sparkles</h3>
    <p>Notes and stars float and fade; nothing strobes. If a child is sensitive to moving light, choose <em>Gentle</em>
      or <em>Calm</em> sparkles in the grown-ups area, and stop using the app if you notice any discomfort.</p>

    <h3>Karaoke</h3>
    <p>Karaoke plays the child's own singing back in the app and nothing more: it cannot record, save or send audio
      anywhere else. You can switch the microphone off in the grown-ups area.</p>

    <h3>Music and artwork</h3>
    <p>All sounds and backing tracks are synthesized by the app. The songs are traditional nursery songs in the public
      domain. The app and its artwork are original HomiLabs work.</p>
  </section>
  <!-- ===== END APP: Tiny Tunes Studio ===== -->

'''

def insert_before(text, anchor, block, page):
    i = text.find(anchor)
    if i < 0:
        sys.exit(f'{page}: anchor not found: {anchor!r}')
    line_start = text.rfind('\n', 0, i) + 1
    return text[:line_start] + block + text[line_start:]


def main(folder):
    d = Path(folder)

    p = d / 'index.html'
    t = p.read_text()
    if 'id="tinytunes"' not in t:
        t = insert_before(t, '<!-- ===== ADD A NEW TOOL =====', CARD, p)
        p.write_text(t)

    for name, section, anchor in (
        ('privacy.html', PRIVACY, '<!-- ===== ADD A TOOL: copy the Beam block above, change id="SLUG", the icon, name, package'),
        ('terms.html', TERMS, '<!-- ===== ADD A TOOL: copy the Beam block above, change id="SLUG", the icon, name and the tool'),
    ):
        p = d / name
        t = p.read_text()
        if 'id="tinytunes"' in t:
            continue
        t = insert_before(t, '<!-- ADD A TOOL: <li><a href="#SLUG">NAME</a></li> -->', TOC, p)
        t = insert_before(t, anchor, section, p)
        t = re.sub(r'Last updated \d{1,2} [A-Z][a-z]+ \d{4}', f'Last updated {DATE}', t, count=1)
        p.write_text(t)
    print(f'{folder}: Tiny Tunes Studio present in all three pages')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'site')
