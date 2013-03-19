<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:date="http://exslt.org/dates-and-times"
  xmlns:func="http://exslt.org/functions"
  xmlns:nml="http://disu.se/software/nml/xsl/1.0/html"
  exclude-result-prefixes="nml"
  extension-element-prefixes="date func">
  <xsl:import href="http://disu.se/software/nml/xsl/1.0/html.xsl"/>

  <xsl:param name="root"/>
  <xsl:param name="path"/>

  <xsl:param name="stylesheet" select="concat($root, '/style.css')"/>

  <func:function name="nml:adjust-uri">
    <xsl:param name="uri" select="@uri"/>

    <xsl:choose>
      <xsl:when test="substring($uri, 1, 1) = '/'">
        <func:result select="concat($root, $uri)"/>
      </xsl:when>

      <xsl:otherwise>
        <func:result select="$uri"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>

  <xsl:template name="html.body.header">
    <header>
      <xsl:choose>
        <xsl:when test="$path != concat($root, '/index.nml')">
          <a
            rel="contents"
            title="Go back to disuse front page"
            href="{$root}/">
            <xsl:call-template name="html.body.header.title"/>
          </a>
        </xsl:when>

        <xsl:otherwise>
          <xsl:call-template name="html.body.header.title"/>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:call-template name="html.body.header.trail"/>

      <!-- TODO: required -->
      <input id="search" name="search" type="search" placeholder="Search"/>
    </header>
  </xsl:template>

  <xsl:template name="html.body.header.title">
    <h1><span class="dis">dis</span><span class="use">u.se</span></h1>
  </xsl:template>

  <xsl:template name="html.body.header.trail">
    <xsl:variable
      name="subpath"
      select="substring($path,
                        string-length($root) + 2,
                        string-length($path) -
                        (string-length($root) + 1) -
                        string-length('/index.nml'))"/>

    <xsl:if test="contains($subpath, '/')">
      <nav id="trail">
        <ol>
          <xsl:call-template name="html.body.header.trail.part">
            <xsl:with-param name="subpath" select="$subpath"/>
          </xsl:call-template>
        </ol>
      </nav>
    </xsl:if>
  </xsl:template>

  <!-- TODO: Clean this up to make it easier to understand. -->
  <xsl:template name="html.body.header.trail.part">
    <xsl:param name="path" select="$root"/>
    <xsl:param name="subpath"/>

    <xsl:variable name="directory" select="substring-before($subpath, '/')"/>
    <xsl:variable name="rest" select="substring-after($subpath, '/')"/>
    <xsl:variable name="more" select="substring-after($rest, '/')"/>

    <li>
      <a
        title="Go back to {$directory}"
        href="{concat($path, '/', $directory, '/')}">
        <!-- TODO: What did we think here?  This needs to be improved. -->
        <xsl:if test="not($more)">
          <xsl:attribute name="rel">up</xsl:attribute>
        </xsl:if>
        <xsl:value-of select="$directory"/>
      </a>
    </li>

    <xsl:if test="$more">
      <xsl:call-template name="html.body.header.trail.part">
        <xsl:with-param name="path" select="concat($path, '/', $directory)"/>
        <xsl:with-param name="subpath" select="$rest"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="html.body.footer">
    <footer>
      <xsl:text>© </xsl:text>
      <xsl:value-of select="date:year()"/>
      <xsl:text> Nikolai Weibull</xsl:text>
    </footer>
  </xsl:template>

  <xsl:template match="subscript">
    <sub>
      <xsl:apply-templates select="@*|node()"/>
    </sub>
  </xsl:template>

  <xsl:template match="superscript">
    <sup>
      <xsl:apply-templates select="@*|node()"/>
    </sup>
  </xsl:template>
</xsl:stylesheet>
