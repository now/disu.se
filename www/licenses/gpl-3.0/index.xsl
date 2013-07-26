<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:func="http://exslt.org/functions"
  xmlns:disuse="http://disu.se/software/disu.se"
  exclude-result-prefixes="disuse"
  extension-element-prefixes="func">
  <xsl:import href="../../../data/templates/disuse.xsl"/>

  <func:function name="disuse:strip-leading-space">
    <xsl:param name="string" select="."/>

    <xsl:variable name="non-spaces" select="translate($string, ' &#x9;&#xa;', '')"/>

    <xsl:choose>
      <xsl:when test="$non-spaces = ''">
        <func:result select="''"/>
      </xsl:when>

      <xsl:otherwise>
        <xsl:variable name="first-non-space" select="substring($non-spaces, 1, 1)"/>
        <xsl:variable name="leading-spaces" select="substring-before($string, $first-non-space)"/>

        <func:result select="substring($string, string-length($leading-spaces) + 1)"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>

  <func:function name="disuse:strip-section-number">
    <xsl:param name="remaining" select="."/>
    <xsl:param name="original" select="."/>
    <xsl:param name="seen-number" select="false()"/>

    <xsl:choose>
      <xsl:when test="translate(substring($remaining, 1, 1), '0123456789', '') = ''">
        <func:result select="disuse:strip-section-number(substring($remaining, 2), $original, true())"/>
      </xsl:when>

      <xsl:when test="$seen-number and substring($remaining, 1, 1) = '.'">
        <func:result select="disuse:strip-leading-space(substring($remaining, 2))"/>
      </xsl:when>

      <xsl:otherwise>
        <func:result select="$original"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>


  <xsl:template match="title/text()[1]">
    <xsl:value-of select="disuse:strip-section-number()"/>
  </xsl:template>
</xsl:stylesheet>
